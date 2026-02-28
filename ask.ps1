param(
    [Parameter(ValueFromPipeline = $true)]
    $PipelineInput,

    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$Arguments,

    [Parameter(Mandatory = $false)]
    [string]$Provider = "anthropic",

    [Parameter(Mandatory = $false)]
    [string]$Model = "",

    [switch]$Help,
    [switch]$ListModels,
    [switch]$Agent,
    [switch]$DryRun,

    [ValidateSet("none","min","auto","full")]
    [string]$Context = "auto",

    [string]$SystemPrompt
)


# Configuration

$VERSION = "0.6.0"
$AUTHOR = "Elias Waly Ba"
$CONFIG_DIR = "$env:USERPROFILE\.config\ask"
$CACHE_DIR = "$env:USERPROFILE\.cache\ask"
$KEYS_FILE = "$CONFIG_DIR\keys.env"
$AGENT_TEMPERATURE = 0.7
$DEFAULT_TEMPERATURE = 1.0


$DEFAULT_MODELS = @{
    anthropic = "claude-sonnet-4-5-20250929"
    openai = "gpt-4o"
    openrouter = "anthropic/claude-sonnet-4-5"
    google = "gemini-2.5-flash"
    deepseek = "deepseek-chat"
}

function Initialize-Config {
    if (-not (Test-Path $CONFIG_DIR)) { 
        New-Item -ItemType Directory -Path $CONFIG_DIR -Force | Out-Null 
    }
    if (-not (Test-Path $CACHE_DIR)) { 
        New-Item -ItemType Directory -Path $CACHE_DIR -Force | Out-Null 
    }
    if (-not (Test-Path $KEYS_FILE)) { 
        New-Item -ItemType File -Path $KEYS_FILE -Force | Out-Null
    }
    Load-Keys
}

function Load-Keys {
    if (Test-Path $KEYS_FILE) {
        Get-Content $KEYS_FILE | ForEach-Object {
            if ($_ -match '^([^=]+)=(.+)$' -and -not $_.StartsWith('#')) {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                if (-not [string]::IsNullOrEmpty($key) -and -not [Environment]::GetEnvironmentVariable($key)) {
                    [Environment]::SetEnvironmentVariable($key, $value, "Process")
                }
            }
        }
    }
}


$AGENT_LOG_FILE = "$CACHE_DIR\agent_history.log"

function Write-AgentLog {
    param(
        [string]$Level,
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [$Level] $Message"
    try {
        Add-Content -Path $AGENT_LOG_FILE -Value $entry -ErrorAction SilentlyContinue
        # Simple log rotation: truncate to last 500 lines if over 1MB
        if (Test-Path $AGENT_LOG_FILE) {
            $fileInfo = Get-Item $AGENT_LOG_FILE -ErrorAction SilentlyContinue
            if ($fileInfo -and $fileInfo.Length -gt 1MB) {
                $lines = Get-Content $AGENT_LOG_FILE -Tail 500
                $lines | Set-Content $AGENT_LOG_FILE
            }
        }
    } catch {
        # Silently ignore logging failures
    }
}

function Test-CommandSafety {
    param([string]$Command)

    $dangerousPatterns = @(
        @{ Pattern = 'Remove-Item\s+.*-Recurse.*-Force\s+[A-Z]:\\$';           Desc = "Remove-Item -Recurse -Force on drive root" }
        @{ Pattern = 'Remove-Item\s+.*-Force.*-Recurse\s+[A-Z]:\\$';           Desc = "Remove-Item -Force -Recurse on drive root" }
        @{ Pattern = 'Remove-Item\s+.*-Recurse.*-Force\s+/\s';                 Desc = "Remove-Item -Recurse -Force /" }
        @{ Pattern = 'Format-Volume';                                            Desc = "Format-Volume" }
        @{ Pattern = 'Clear-Disk';                                               Desc = "Clear-Disk" }
        @{ Pattern = 'Stop-Computer';                                            Desc = "Stop-Computer (shutdown)" }
        @{ Pattern = 'Restart-Computer';                                         Desc = "Restart-Computer (reboot)" }
        @{ Pattern = 'iex\s*\(\s*iwr';                                          Desc = "iex(iwr ...) - remote code execution" }
        @{ Pattern = 'Invoke-Expression\s*\(\s*Invoke-WebRequest';              Desc = "Invoke-Expression(Invoke-WebRequest ...) - remote code execution" }
        @{ Pattern = 'iex\s*\(\s*Invoke-WebRequest';                            Desc = "iex(Invoke-WebRequest ...) - remote code execution" }
        @{ Pattern = 'Invoke-Expression\s*\(\s*iwr';                            Desc = "Invoke-Expression(iwr ...) - remote code execution" }
        @{ Pattern = 'Set-MpPreference\s+.*-DisableRealtimeMonitoring\s+\$true'; Desc = "Disabling Windows Defender" }
        @{ Pattern = 'rm\s+-rf\s+/';                                            Desc = "rm -rf /" }
        @{ Pattern = 'mkfs\.';                                                   Desc = "mkfs (format filesystem)" }
        @{ Pattern = 'dd\s+.*of=/dev/';                                          Desc = "dd to device" }
    )

    foreach ($entry in $dangerousPatterns) {
        if ($Command -match $entry.Pattern) {
            Write-Host "⛔ BLOCKED: $($entry.Desc)" -ForegroundColor Red
            Write-Host "   Command: $Command" -ForegroundColor Red
            Write-AgentLog "BLOCKED" "Pattern=$($entry.Desc) Command=$Command"
            return $false
        }
    }
    return $true
}

function Manage-Keys {
    param(
        [string]$Action,
        [string]$Provider,
        [string]$Key
    )
    
    if ($Action -eq "set") {
        if ([string]::IsNullOrEmpty($Provider)) {
            Write-Host "Error: Provider required" -ForegroundColor Red
            Write-Host "Usage: ask keys set provider" -ForegroundColor Cyan
            Write-Host "Providers: anthropic, openai, openrouter, google, deepseek" -ForegroundColor Cyan
            return
        }
        
        $keyVar = ""
        if ($Provider -eq "anthropic") { $keyVar = "ANTHROPIC_API_KEY" }
        elseif ($Provider -eq "openai") { $keyVar = "OPENAI_API_KEY" }
        elseif ($Provider -eq "openrouter") { $keyVar = "OPENROUTER_API_KEY" }
        elseif ($Provider -eq "google") { $keyVar = "GOOGLE_API_KEY" }
        elseif ($Provider -eq "deepseek") { $keyVar = "DEEPSEEK_API_KEY" }
        else {
            Write-Host "Unknown provider: $Provider" -ForegroundColor Red
            Write-Host "Valid providers: anthropic, openai, openrouter, google, deepseek" -ForegroundColor Cyan
            return
        }
        
        if ([string]::IsNullOrEmpty($Key)) {
            Write-Host "Enter your $Provider API key (input hidden):" -ForegroundColor Cyan
            $secureKey = Read-Host -AsSecureString

            $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
            try {
                $Key = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)
            }
            finally {
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
            }

        }
        
        if ([string]::IsNullOrEmpty($Key)) {
            Write-Host "Error: No key provided" -ForegroundColor Red
            return
        }
        
        # Remove existing key from file
        if (Test-Path $KEYS_FILE) {
            $content = Get-Content $KEYS_FILE | Where-Object { -not $_.StartsWith("$keyVar=") }
            $content | Set-Content $KEYS_FILE
        }
        
        # Add new key
        Add-Content -Path $KEYS_FILE -Value "$keyVar=$Key"
        
        # Update environment
        [Environment]::SetEnvironmentVariable($keyVar, $Key, "Process")
        
        Write-Host "✓ $Provider API key saved" -ForegroundColor Green
        Write-Host "Stored in: $KEYS_FILE" -ForegroundColor Cyan
    }
    elseif ($Action -eq "list") {
        Write-Host "Configured API Keys:" -ForegroundColor Cyan
        Write-Host ""
        
        $found = $false
        @("anthropic", "openai", "openrouter", "google", "deepseek") | ForEach-Object {
            $providerName = $_
            $keyVar = ""
            if ($providerName -eq "anthropic") { $keyVar = "ANTHROPIC_API_KEY" }
            elseif ($providerName -eq "openai") { $keyVar = "OPENAI_API_KEY" }
            elseif ($providerName -eq "openrouter") { $keyVar = "OPENROUTER_API_KEY" }
            elseif ($providerName -eq "google") { $keyVar = "GOOGLE_API_KEY" }
            elseif ($providerName -eq "deepseek") { $keyVar = "DEEPSEEK_API_KEY" }
            
            $keyValue = [Environment]::GetEnvironmentVariable($keyVar)
            
            if ([string]::IsNullOrEmpty($keyValue) -and (Test-Path $KEYS_FILE)) {
                $line = Get-Content $KEYS_FILE | Where-Object { $_.StartsWith("$keyVar=") } | Select-Object -First 1
                if ($line -match '=(.+)$') {
                    $keyValue = $matches[1]
                }
            }
            
            if (-not [string]::IsNullOrEmpty($keyValue)) {
                $maskedKey = if ($keyValue.Length -ge 12) {
                    $keyValue.Substring(0, 8) + "..." + $keyValue.Substring($keyValue.Length - 4)
                } else {
                    "***"
                }
                
                $source = if ((Test-Path $KEYS_FILE) -and (Get-Content $KEYS_FILE | Where-Object { $_.StartsWith("$keyVar=") })) {
                    "file"
                } else {
                    "env"
                }
                
                Write-Host "✓ " -NoNewline
                Write-Host "$providerName`: $maskedKey " -NoNewline -ForegroundColor Green
                Write-Host "($source)" -ForegroundColor DarkGray
                $found = $true
            } else {
                Write-Host "○ " -NoNewline
                Write-Host "$providerName`: not set" -ForegroundColor DarkGray
            }
        }
        
        if (-not $found) {
            Write-Host ""
            Write-Host "No API keys configured" -ForegroundColor Yellow
            Write-Host "Set a key with: ask keys set provider" -ForegroundColor Cyan
        }
    }
    elseif ($Action -eq "remove") {
        if ([string]::IsNullOrEmpty($Provider)) {
            Write-Host "Error: Provider required" -ForegroundColor Red
            Write-Host "Usage: ask keys remove provider" -ForegroundColor Cyan
            return
        }
        
        $keyVar = ""
        if ($Provider -eq "anthropic") { $keyVar = "ANTHROPIC_API_KEY" }
        elseif ($Provider -eq "openai") { $keyVar = "OPENAI_API_KEY" }
        elseif ($Provider -eq "openrouter") { $keyVar = "OPENROUTER_API_KEY" }
        elseif ($Provider -eq "google") { $keyVar = "GOOGLE_API_KEY" }
        elseif ($Provider -eq "deepseek") { $keyVar = "DEEPSEEK_API_KEY" }
        else {
            Write-Host "Unknown provider: $Provider" -ForegroundColor Red
            return
        }
        
        if (Test-Path $KEYS_FILE) {
            $content = Get-Content $KEYS_FILE | Where-Object { -not $_.StartsWith("$keyVar=") }
            $content | Set-Content $KEYS_FILE
        }
        
        [Environment]::SetEnvironmentVariable($keyVar, $null, "Process")
        
        Write-Host "✓ $Provider API key removed" -ForegroundColor Green
    }
    elseif ($Action -eq "path") {
        Write-Host $KEYS_FILE
    }
    else {
        Write-Host "Usage:" -ForegroundColor Yellow
        Write-Host "  ask keys set provider     Set API key for provider" -ForegroundColor Cyan
        Write-Host "  ask keys list             List configured keys" -ForegroundColor Cyan
        Write-Host "  ask keys remove provider  Remove API key" -ForegroundColor Cyan
        Write-Host "  ask keys path             Show keys file location" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Providers: anthropic, openai, openrouter, google, deepseek" -ForegroundColor Yellow
    }
}

function Check-APIKey {
    param($provider)
    
    $keyVar = ""
    if ($provider -eq "anthropic") { $keyVar = "ANTHROPIC_API_KEY" }
    elseif ($provider -eq "openai") { $keyVar = "OPENAI_API_KEY" }
    elseif ($provider -eq "openrouter") { $keyVar = "OPENROUTER_API_KEY" }
    elseif ($provider -eq "google") { $keyVar = "GOOGLE_API_KEY" }
    elseif ($provider -eq "deepseek") { $keyVar = "DEEPSEEK_API_KEY" }
    
    if ([string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable($keyVar))) {
        Write-Host "Error: $keyVar not set" -ForegroundColor Red
        Write-Host ""
        Write-Host "Set up your API key:" -ForegroundColor Yellow
        Write-Host "  ask keys set $provider" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Or use environment variable:" -ForegroundColor Yellow
        Write-Host "  `$env:$keyVar = 'your-key-here'" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Get an API key:" -ForegroundColor Yellow
        if ($provider -eq "anthropic") { Write-Host "  https://console.anthropic.com/" -ForegroundColor Green }
        elseif ($provider -eq "openai") { Write-Host "  https://platform.openai.com/api-keys" -ForegroundColor Green }
        elseif ($provider -eq "openrouter") { Write-Host "  https://openrouter.ai/keys" -ForegroundColor Green }
        elseif ($provider -eq "google") { Write-Host "  https://aistudio.google.com/apikey" -ForegroundColor Green }
        elseif ($provider -eq "deepseek") { Write-Host "  https://platform.deepseek.com/" -ForegroundColor DarkGray }
        exit 1
    }
}

function Get-APIUrl {
    param($provider)
    
    if ($provider -eq "anthropic") { return "https://api.anthropic.com/v1/messages" }
    elseif ($provider -eq "openai") { return "https://api.openai.com/v1/chat/completions" }
    elseif ($provider -eq "openrouter") { return "https://openrouter.ai/api/v1/chat/completions" }
    elseif ($provider -eq "google") { return "https://generativelanguage.googleapis.com/v1beta/models" }
    elseif ($provider -eq "deepseek") { return "https://api.deepseek.com/v1/chat/completions" }
}


function Get-Models {
    param($provider)

    Write-Host "Available models for $provider :" -ForegroundColor Cyan

    $models = @()
    if ($provider -eq "anthropic") {
        $models = @("claude-sonnet-4-5-20250929", "claude-opus-4-1-20250514", "claude-4-opus-20250514")
    }
    elseif ($provider -eq "openai") {
        $models = @("gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "o1", "o1-mini")
    }
    elseif ($provider -eq "openrouter") {
        $models = @("anthropic/claude-sonnet-4-5", "openai/gpt-4o", "google/gemini-2.0-flash-exp")
    }
    elseif ($provider -eq "google") {
        $models = @("gemini-3-pro-preview", "gemini-2.5-pro", "gemini-2.5-flash", "gemini-2.5-flash-lite")
    }
    elseif ($provider -eq "deepseek") {
        $models = @("deepseek-chat", "deepseek-coder", "deepseek-reasoner")
    }
    
    $models | ForEach-Object {
        Write-Host "  → " -NoNewline
        Write-Host $_ -ForegroundColor Green
    }
}

function Gather-Context {
    param([string]$Level = "auto")
    
    $context = ""
    
    if ($Level -eq "min") {
        $context += "Working directory: $(Get-Location)`n"
        $context += "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
    }
    elseif ($Level -eq "auto" -or $Level -eq "full") {
        $context += "System: $([Environment]::OSVersion.VersionString)`n"
        $context += "Working directory: $(Get-Location)`n"
        $context += "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
        
        # Check if we're in a git repo
        try {
            $gitBranch = git branch --show-current 2>$null
            if ($LASTEXITCODE -eq 0) {
                $context += "Git branch: $gitBranch`n"
                $gitStatus = git status --short 2>$null | Select-Object -First 5
                if ($gitStatus) {
                    $context += "Git status:`n$gitStatus`n"
                }
            }
        } catch {
            # Git not available or not a repo
        }
        
        if ($Level -eq "full") {
            $context += "Shell: PowerShell $($PSVersionTable.PSVersion)`n"
            $context += "User: $env:USERNAME`n"
            
            # Try to get last command
            try {
                $lastCmd = Get-History -Count 1 2>$null
                if ($lastCmd) {
                    $context += "Last command: $($lastCmd.CommandLine)`n"
                }
            } catch {
                # History not available
            }
        }
    }
    
    return $context
}

function Invoke-AgentMode {
    param(
        [string]$Task,
        [string]$Provider,
        [string]$Model,
        [string]$SystemPrompt,
        [switch]$DryRun
    )

    Write-AgentLog "INFO" "Agent session started Task=$Task"

    Write-Host "🤖 Agent Mode Activated" -ForegroundColor Cyan
    Write-Host "Task: $Task" -ForegroundColor Yellow
    Write-Host "---" -ForegroundColor DarkGray

    Write-Host "[1/3] Planning the task..." -ForegroundColor Cyan

    $context = Gather-Context "min"

    $planPrompt = @"
Return a JSON array. No other text, no markdown fences.

Schema:
[{"step": int, "description": string, "command": string, "risk": "low"|"medium"|"high"}]

Environment variables available to commands:
- `$env:ASK_LAST_OUTPUT contains the stdout of the previous step
- `$env:ASK_PREV_OUTPUTS contains all prior step outputs separated by ---

Risk levels: low = read-only, medium = creates/modifies files, high = deletes/destroys data.

Correct example:
[{"step":1,"description":"List text files","command":"Get-ChildItem -Path . -Filter *.txt","risk":"low"},{"step":2,"description":"Count files found","command":"(`$env:ASK_LAST_OUTPUT -split \"`n\").Count","risk":"low"}]

Wrong (do NOT do this):
```json
[...]
```

Context:
$context

Task: $Task
"@

    Write-Host "Planning the task..." -ForegroundColor DarkGray
    $planJson = Call-API -Provider $Provider -Model $Model -Prompt $planPrompt `
        -SystemPrompt ($SystemPrompt + " You are a PowerShell expert. Respond ONLY with valid JSON.") `
        -Temperature $AGENT_TEMPERATURE

    if (-not $planJson) {
        Write-Host "❌ Planning failed" -ForegroundColor Red
        Write-AgentLog "ERROR" "Planning API call failed"
        return
    }

    $plan = Extract-JsonFromResponse -Response $planJson

    if (-not $plan) {
        Write-Host "❌ Unable to parse JSON plan" -ForegroundColor Red
        Write-Host "Response received:" -ForegroundColor Yellow
        Write-Host $planJson -ForegroundColor Gray
        Write-AgentLog "ERROR" "Failed to parse plan JSON"
        return
    }

    Write-AgentLog "INFO" "Plan generated Steps=$($plan.Count)"

    Write-Host "`n📋 Generated plan ($($plan.Count) steps):" -ForegroundColor Cyan
    $stepNumber = 1
    foreach ($step in $plan) {
        $riskColor = @{low = "Green"; medium = "Yellow"; high = "Red"}[$step.risk]
        Write-Host "`n  [$($stepNumber)] " -NoNewline -ForegroundColor Cyan
        Write-Host $step.description -ForegroundColor White
        Write-Host "     Risk: " -NoNewline
        Write-Host $step.risk -ForegroundColor $riskColor

        if ($step.command.Length -gt 100) {
            Write-Host "     Command: " -NoNewline -ForegroundColor Yellow
            Write-Host $step.command.Substring(0, 100) -ForegroundColor Gray -NoNewline
            Write-Host "..." -ForegroundColor DarkGray
        } else {
            Write-Host "     Command: " -NoNewline -ForegroundColor Yellow
            Write-Host $step.command -ForegroundColor Gray
        }

        $stepNumber++
    }

    Write-Host "`n---" -ForegroundColor DarkGray

    if ($DryRun) {
        Write-Host "🏜️  Dry run - no commands executed" -ForegroundColor Yellow
        Write-AgentLog "INFO" "Dry run completed"
        return
    }

    Write-Host "[2/3] Execution confirmation" -ForegroundColor Cyan
    $confirmation = Read-Host "Execute plan? (Y/N/Detailed) [N]"

    if ($confirmation -match '^[Yy]') {
        Invoke-AutoAgentExecution -Plan $plan
    }
    elseif ($confirmation -match '^[Dd]') {
        Invoke-DetailedAgentExecution -Plan $plan
    }
    else {
        Write-Host "❌ Execution cancelled" -ForegroundColor Yellow
        return
    }

    Write-AgentLog "INFO" "Agent session completed"
}
function Extract-JsonFromResponse {
    param([string]$Response)

    $cleanResponse = $Response.Trim()

    # Strip markdown fences
    $cleanResponse = $cleanResponse -replace '^```(?:json)?\s*\n?', ''
    $cleanResponse = $cleanResponse -replace '\n?```$', ''
    $cleanResponse = $cleanResponse.Trim()

    # Method 1: Direct parse
    try {
        return $cleanResponse | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        # Method 2: Regex extraction
        $jsonPattern = '\[\s*\{[\s\S]*?\}\s*\]'
        $match = [regex]::Match($cleanResponse, $jsonPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

        if ($match.Success) {
            $jsonText = $match.Value
            $jsonText = $jsonText -replace '[\r\n]+', ' '
            $jsonText = $jsonText -replace '\s+', ' '

            try {
                return $jsonText | ConvertFrom-Json -ErrorAction Stop
            }
            catch {
                Write-Host "❌ JSON extraction failed" -ForegroundColor Red
            }
        }

        return $null
    }
}

function Invoke-StepCommand {
    param(
        [string]$Command,
        [string]$StepNumber,
        [switch]$Silent
    )

    # Check against dangerous command blocklist
    if (-not (Test-CommandSafety $Command)) {
        return @{ Success = $false; Output = "[BLOCKED - dangerous command]" }
    }

    Write-AgentLog "EXEC" "Step=$StepNumber Command=$Command"

    try {
        Write-Host "🔄 Executing..." -ForegroundColor Cyan

        $scriptBlock = [ScriptBlock]::Create($Command)

        $output = & $scriptBlock 2>&1

        $errors = $output | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }

        if ($errors) {
            foreach ($err in $errors) {
                Write-Host "⚠️ Command warning/error: $($err.Exception.Message)" -ForegroundColor Yellow
            }
        }

        $normalOutput = $output | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] }
        $outputStr = if ($normalOutput) { ($normalOutput | Out-String).Trim() } else { "" }

        if (-not $Silent -and $normalOutput) {
            Write-Host "📤 Output:" -ForegroundColor Green
            $normalOutput | Out-Host
        }

        Write-Host "✓ Step $StepNumber completed" -ForegroundColor Green
        Write-AgentLog "INFO" "Step=$StepNumber Status=success"
        return @{ Success = $true; Output = $outputStr }
    }
    catch {
        Write-Host "❌ Error: " -NoNewline -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-AgentLog "ERROR" "Step=$StepNumber Error=$($_.Exception.Message)"
        return @{ Success = $false; Output = $_.Exception.Message }
    }
}

function Invoke-AutoAgentExecution {
    param($Plan)

    Write-Host "[3/3] Automatic execution..." -ForegroundColor Cyan

    $successCount = 0
    $errorCount = 0
    $skippedCount = 0
    $allOutputs = @()

    foreach ($step in $Plan) {
        Write-Host "`n--- Step $($step.step)/$($Plan.Count) ---" -ForegroundColor DarkGray
        Write-Host "📝 $($step.description)" -ForegroundColor Cyan

        $riskColor = @{low = "Green"; medium = "Yellow"; high = "Red"}[$step.risk]
        Write-Host "⚠️  Risk level: " -NoNewline
        Write-Host $step.risk -ForegroundColor $riskColor

        Write-Host "⚡ Command:" -ForegroundColor Yellow
        Write-Host $step.command -ForegroundColor Gray

        if ($step.risk -eq "high") {
            Write-Host "`n⚠️  ⚠️  ⚠️  HIGH RISK OPERATION ⚠️  ⚠️  ⚠️" -ForegroundColor Red -BackgroundColor Black
            Write-Host "This step could potentially:" -ForegroundColor Yellow
            Write-Host "  • Delete or modify important data" -ForegroundColor Yellow
            Write-Host "  • Change system settings" -ForegroundColor Yellow
            Write-Host "  • Affect system stability" -ForegroundColor Yellow

            $highRiskConfirm = Read-Host "`nExecute this high-risk step? (Y/N/Skip) [N]"

            switch ($highRiskConfirm.ToUpper()) {
                'Y' {
                    Write-Host "Proceeding with high-risk step..." -ForegroundColor Yellow
                }
                'Skip' {
                    Write-Host "⏭️ High-risk step skipped" -ForegroundColor Yellow
                    $skippedCount++
                    continue
                }
                default {
                    Write-Host "⏹️ Execution cancelled by user" -ForegroundColor Yellow
                    Display-ExecutionSummary -Success $successCount -Error $errorCount -Skipped $skippedCount -Total $Plan.Count
                    return
                }
            }
        }

        $result = Invoke-StepCommand -Command $step.command -StepNumber $step.step

        # Track outputs for forwarding
        $allOutputs += "[Step $($step.step)] $($result.Output)"
        [Environment]::SetEnvironmentVariable("ASK_LAST_OUTPUT", $result.Output, "Process")
        [Environment]::SetEnvironmentVariable("ASK_PREV_OUTPUTS", ($allOutputs -join "`n---`n"), "Process")

        if ($result.Success) {
            $successCount++
        }
        else {
            Write-Host "`n❌ Step failed!" -ForegroundColor Red
            $continue = Read-Host "Continue with remaining steps? (Y/N) [N]"

            if ($continue -notmatch '^[Yy]') {
                Write-Host "⏹️ Execution interrupted" -ForegroundColor Yellow
                Display-ExecutionSummary -Success $successCount -Error $errorCount -Skipped $skippedCount -Total $Plan.Count
                return
            }
            $errorCount++
        }

        if ($step.step -lt $Plan.Count) {
            Start-Sleep -Milliseconds 500
        }
    }

    Display-ExecutionSummary -Success $successCount -Error $errorCount -Skipped $skippedCount -Total $Plan.Count
}

function Invoke-DetailedAgentExecution {
    param($Plan)

    Write-Host "[3/3] Step-by-step execution..." -ForegroundColor Cyan

    $successCount = 0
    $errorCount = 0
    $skippedCount = 0
    $allOutputs = @()

    foreach ($step in $Plan) {
        Write-Host "`n--- Step $($step.step)/$($Plan.Count) ---" -ForegroundColor DarkGray
        Write-Host "📝 $($step.description)" -ForegroundColor Cyan

        $riskColor = @{low = "Green"; medium = "Yellow"; high = "Red"}[$step.risk]
        Write-Host "⚠️  Risk: " -NoNewline
        Write-Host $step.risk -ForegroundColor $riskColor

        Write-Host "⚡ Command:" -ForegroundColor Yellow
        Write-Host $step.command -ForegroundColor Gray

        Write-Host "`nOptions:" -ForegroundColor Cyan
        Write-Host "  [E] Execute this step" -ForegroundColor Green
        Write-Host "  [S] Skip this step" -ForegroundColor Yellow
        Write-Host "  [M] Modify command before execution" -ForegroundColor Cyan
        Write-Host "  [A] Stop execution" -ForegroundColor Red

        $choice = Read-Host "`nYour choice [E]"
        $result = $null

        switch ($choice.ToUpper()) {
            'E' {
                $result = Invoke-StepCommand -Command $step.command -StepNumber $step.step
                if ($result.Success) { $successCount++ } else { $errorCount++ }
            }
            'S' {
                Write-Host "⏭️ Step $($step.step) skipped" -ForegroundColor Yellow
                $skippedCount++
                continue
            }
            'M' {
                Write-Host "✏️  Modifying command:" -ForegroundColor Cyan
                Write-Host "Current command:" -ForegroundColor Yellow
                Write-Host $step.command -ForegroundColor Gray

                $newCommand = Read-Host "`nNew command (leave empty to cancel)"

                if (-not [string]::IsNullOrWhiteSpace($newCommand)) {
                    # Check safety of modified command too
                    if (-not (Test-CommandSafety $newCommand)) {
                        Write-Host "⚠️ Modified command blocked" -ForegroundColor Yellow
                        $skippedCount++
                        continue
                    }
                    $result = Invoke-StepCommand -Command $newCommand -StepNumber $step.step
                    if ($result.Success) { $successCount++ } else { $errorCount++ }
                } else {
                    Write-Host "⚠️ Modification cancelled" -ForegroundColor Yellow
                    $skippedCount++
                }
            }
            'A' {
                Write-Host "⏹️ Execution stopped" -ForegroundColor Yellow
                Display-ExecutionSummary -Success $successCount -Error $errorCount -Skipped $skippedCount -Total $Plan.Count
                return
            }
            default {
                $result = Invoke-StepCommand -Command $step.command -StepNumber $step.step
                if ($result.Success) { $successCount++ } else { $errorCount++ }
            }
        }

        # Track outputs for forwarding
        if ($result) {
            $allOutputs += "[Step $($step.step)] $($result.Output)"
            [Environment]::SetEnvironmentVariable("ASK_LAST_OUTPUT", $result.Output, "Process")
            [Environment]::SetEnvironmentVariable("ASK_PREV_OUTPUTS", ($allOutputs -join "`n---`n"), "Process")
        }

        if ($step.step -lt $Plan.Count) {
            Start-Sleep -Milliseconds 500
        }
    }

    Display-ExecutionSummary -Success $successCount -Error $errorCount -Skipped $skippedCount -Total $Plan.Count
}

function Display-ExecutionSummary {
    param(
        [int]$Success,
        [int]$Errors,
        [int]$Skipped = 0,
        [int]$Total
    )
    
    Write-Host "`n--- Summary ---" -ForegroundColor DarkGray
    Write-Host "✅ Success: $Success" -ForegroundColor Green
    Write-Host "❌ Errors: $Errors" -ForegroundColor $(if ($Error -gt 0) { "Red" } else { "Gray" })
    
    if ($Skipped -gt 0) {
        Write-Host "⏭️ Skipped: $Skipped" -ForegroundColor Yellow
    }
    
    Write-Host "📊 Total: $Total steps" -ForegroundColor Cyan
}

function Call-API {
    param(
        $provider,
        $model,
        $prompt,
        $systemPrompt = "You are a helpful AI assistant for the command line. Provide concise, accurate answers. When writing code or commands, ensure they are correct and safe.",
        $temperature = $DEFAULT_TEMPERATURE,
        $maxTokens = 4096
    )
    
    $apiUrl = Get-APIUrl $provider
    $response = ""
    
    
    try {
        if ($provider -eq "anthropic") {
            $headers = @{
                "Content-Type" = "application/json"
                "x-api-key" = $env:ANTHROPIC_API_KEY
                "anthropic-version" = "2023-06-01"
            }
            
            $body = @{
                model = $model
                messages = @(@{
                    role = "user"
                    content = $prompt
                })
                system = $systemPrompt
                max_tokens = $maxTokens
                temperature = $temperature
            } | ConvertTo-Json -Depth 10
            
            $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $body
          
            return $response.content[0].text
        }
        elseif ($provider -eq "openai") {
            $headers = @{
                "Content-Type" = "application/json"
                "Authorization" = "Bearer $env:OPENAI_API_KEY"
            }
            
            $messages = @(@{
                role = "user"
                content = $prompt
            })
            
            if (-not [string]::IsNullOrEmpty($systemPrompt)) {
                $messages = @(@{
                    role = "system"
                    content = $systemPrompt
                }) + $messages
            }
            
            $body = @{
                model = $model
                messages = $messages
                temperature = $temperature
                max_tokens = $maxTokens
            } | ConvertTo-Json -Depth 10
            
            $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $body
        
            return $response.choices[0].message.content
        }
        elseif ($provider -eq "openrouter") {
            $headers = @{
                "Content-Type" = "application/json"
                "Authorization" = "Bearer $env:OPENROUTER_API_KEY"
            }
            
            $messages = @(@{
                role = "user"
                content = $prompt
            })
            
            if (-not [string]::IsNullOrEmpty($systemPrompt)) {
                $messages = @(@{
                    role = "system"
                    content = $systemPrompt
                }) + $messages
            }
            
            $body = @{
                model = $model
                messages = $messages
                temperature = $temperature
                max_tokens = $maxTokens
            } | ConvertTo-Json -Depth 10
            
            $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $body
           
            return $response.choices[0].message.content
        }
        elseif ($provider -eq "google") {
            
            $fullUrl = "$apiUrl/${model}:generateContent"

            $headers = @{
                "Content-Type" = "application/json"
                "x-goog-api-key" = $env:GOOGLE_API_KEY
            }
            
            $body = @{
                system_instruction = @{
                    parts = @(@{
                        text = $systemPrompt
                    })
                }
                contents = @(@{
                    parts = @(@{
                        text = $prompt
                    })
                })
                generationConfig = @{
                    temperature = $temperature
                    maxOutputTokens = $maxTokens
                }
            } | ConvertTo-Json -Depth 10
            
            $response = Invoke-RestMethod -Uri $fullUrl -Method Post -Headers $headers -Body $body
            
           
            if ($response.error) {
                Write-Host "Error from Gemini API: " -NoNewline -ForegroundColor Red
                Write-Host $response.error.message -ForegroundColor Red
                if ($response.error.message -match "quota" -or $response.error.code -eq 429) {
                    Write-Host "Tip: Some Gemini models may require a paid plan." -ForegroundColor Yellow
                    Write-Host "Try: ask -Provider google -Model gemini-2.0-flash 'your question'" -ForegroundColor Yellow
                }
                return $null
            }
            
            return $response.candidates[0].content.parts[0].text
        }
        elseif ($provider -eq "deepseek") {
            $headers = @{
                "Content-Type" = "application/json"
                "Authorization" = "Bearer $env:DEEPSEEK_API_KEY"
            }
            
            $messages = @(@{
                role = "user"
                content = $prompt
            })
            
            if (-not [string]::IsNullOrEmpty($systemPrompt)) {
                $messages = @(@{
                    role = "system"
                    content = $systemPrompt
                }) + $messages
            }
            
            $body = @{
                model = $model
                messages = $messages
                temperature = $temperature
                max_tokens = $maxTokens
            } | ConvertTo-Json -Depth 10
            
            $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $body
        
            return $response.choices[0].message.content
        }
    }
   catch {
    Write-Host "API Error: " -NoNewline -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    $resp = $_.Exception.Response

    if ($resp) {
        try {
            
            if ($resp -is [System.Net.HttpWebResponse]) {
                $stream = $resp.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($stream)
                $body = $reader.ReadToEnd()
            }
           
            elseif ($resp -is [System.Net.Http.HttpResponseMessage]) {
                $body = $resp.Content.ReadAsStringAsync().Result
            }

            if ($body) {
                $json = $body | ConvertFrom-Json -ErrorAction SilentlyContinue
                if ($json -and $json.error) {
                    Write-Host "Details: " -NoNewline -ForegroundColor Red
                    Write-Host $json.error.message -ForegroundColor Red
                }
            }
        }
        catch {
            # Swallow parsing errors – never crash error handler
        }
    }

    if ($_.Exception.Message -match '429') {
        Write-Host ""
        Write-Host "Tip:" -ForegroundColor Yellow
        Write-Host "  You are being rate-limited by OpenAI." -ForegroundColor Yellow
        Write-Host "  Check your quota or slow down requests." -ForegroundColor Yellow
        Write-Host "  https://platform.openai.com/usage" -ForegroundColor Green
    }

    return $null
}

}

function Show-Help {
    Write-Host "ask - v$VERSION" -ForegroundColor Cyan
    Write-Host "AI-powered shell assistant for PowerShell" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "    ask [OPTIONS] [PROMPT]"
    Write-Host "    ask [OPTIONS]              # Interactive mode"
    Write-Host "    COMMAND | ask [PROMPT]     # Pipe input"
    Write-Host ""
    Write-Host "OPTIONS:" -ForegroundColor Yellow
    Write-Host "    -Agent               Enable agent mode for multi-step task execution"
    Write-Host "    -DryRun              Show agent plan without executing (implies -Agent)"
    Write-Host "    -Provider PROVIDER   Provider: anthropic, openai, openrouter, google, deepseek"
    Write-Host "                              [default: anthropic]"
    Write-Host "    -Model MODEL         Model name"
    Write-Host "    -Context LEVEL       Context level: none, min, auto, full [default: auto]"
    Write-Host "    -SystemPrompt TEXT   Custom system prompt"
    Write-Host "    -ListModels          List available models for provider"
    Write-Host ""
    Write-Host "KEY MANAGEMENT:" -ForegroundColor Yellow
    Write-Host "    ask keys set provider     Set API key for provider"
    Write-Host "    ask keys list             List configured keys"
    Write-Host "    ask keys remove provider  Remove API key"
    Write-Host "    ask keys path             Show keys file location"
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "    ask keys set anthropic"
    Write-Host "    ask 'how do I list services in Windows?'"
    Write-Host "    ask -Provider openai 'explain this PowerShell script'"
    Write-Host "    Get-ChildItem | ask -Context full 'what files do I have?'"
    Write-Host "    ask -Agent 'clean up temp files older than 30 days'"
    Write-Host ""
    Write-Host "https://github.com/elias-ba/ask" -ForegroundColor DarkGray
}

function Main {
    
    if ($Arguments.Count -gt 0 -and $Arguments[0] -eq "keys") {
        Initialize-Config
        $action   = if ($Arguments.Count -gt 1) { $Arguments[1] } else { $null }
        $provider = if ($Arguments.Count -gt 2) { $Arguments[2] } else { $null }
        $key      = if ($Arguments.Count -gt 3) { $Arguments[3] } else { $null }
        
        Manage-Keys -Action $action -Provider $provider -Key $key
        return
    }
    
 
    if ($Help) {
        Show-Help
        return
    }
    
  
    Initialize-Config
    
    if ([string]::IsNullOrEmpty($Model)) {
        $Model = $DEFAULT_MODELS[$Provider]
    }
    
   
    Check-APIKey $Provider
    

    if ($ListModels) {
        Get-Models $Provider
        return
    }
    
    $userPrompt = ""
    if ([string]::IsNullOrEmpty($userPrompt) -and $Arguments.Count -gt 0) {
        $userPrompt = $Arguments -join " "
    }
    
    # Handle pipeline input
    $pipedInput = ""
    if ($PipelineInput) {
        $pipedInput = $PipelineInput | Out-String
    }
    
    # Combine pipeline input with user prompt
    if (-not [string]::IsNullOrEmpty($pipedInput)) {
        if (-not [string]::IsNullOrEmpty($userPrompt)) {
            $userPrompt = "Input:`n$pipedInput`n`nQuestion: $userPrompt"
        } else {
            $userPrompt = $pipedInput
        }
    }
    

    # -DryRun implies -Agent
    if ($DryRun) { $Agent = $true }

    if ($Agent) {
        if ([string]::IsNullOrEmpty($userPrompt)) {
            Write-Host "❌ Agent mode requires a task" -ForegroundColor Red
            Write-Host "Usage: ask --agent 'your task here'" -ForegroundColor Cyan
            return
        }

        if ($Context -eq "auto") {
            $Context = "min"
        }

        if ($Context -ne "none" -and -not [string]::IsNullOrEmpty($userPrompt)) {
            $ctx = Gather-Context $Context
            if (-not [string]::IsNullOrEmpty($ctx)) {
                $userPrompt = "Context: $ctx`n`nTask: $userPrompt"
            }
        }

        $agentParams = @{
            Task = $userPrompt
            Provider = $Provider
            Model = $Model
            SystemPrompt = $SystemPrompt
        }
        if ($DryRun) { $agentParams.DryRun = $true }

        Invoke-AgentMode @agentParams
        return
    }
    
    if ($Context -ne "none" -and -not [string]::IsNullOrEmpty($userPrompt)) {
        $ctx = Gather-Context $Context
        if (-not [string]::IsNullOrEmpty($ctx)) {
            $userPrompt = "Context about my system:`n$ctx`n`nQuestion: $userPrompt"
        }
    }
    
    if (-not [string]::IsNullOrEmpty($userPrompt)) {
        $response = Call-API -Provider $Provider -Model $Model -Prompt $userPrompt `
            -SystemPrompt $SystemPrompt
        
        if ($response) {
            Write-Host $response
        }
    } else {
        Write-Host "Interactive mode not yet implemented" -ForegroundColor Cyan
        Write-Host "Please provide a prompt. Example:" -ForegroundColor Yellow
        Write-Host "  ask 'your question here'" -ForegroundColor Green
    }
}

try {
    Main
}
catch {
    Write-Host "Error: " -NoNewline -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "For help: ask -Help" -ForegroundColor Yellow
}
