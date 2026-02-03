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

    [ValidateSet("none","min","auto","full")]
    [string]$Context = "auto",

    [string]$SystemPrompt
)


# Configuration
$VERSION = "1.0.0"
$CONFIG_DIR = "$env:USERPROFILE\.config\ask"
$CACHE_DIR = "$env:USERPROFILE\.cache\ask"
$KEYS_FILE = "$CONFIG_DIR\keys.env"


$DEFAULT_MODELS = @{
    anthropic = "claude-3-sonnet-20240229"
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


function Get_models {
    param($provider)
    
    Write-Host "Available models for $provider :" -ForegroundColor Cyan
    
    $models = @()
    if ($provider -eq "anthropic") { 
        $models = @("claude-3-sonnet-20240229", "claude-3-opus-20240229", "claude-3-haiku-20240307") 
    }
    elseif ($provider -eq "openai") { 
        $models = @("gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "o1", "o1-mini") 
    }
    elseif ($provider -eq "openrouter") { 
        $models = @("anthropic/claude-3-sonnet", "openai/gpt-4o", "google/gemini-2.0-flash-exp") 
    }
    elseif ($provider -eq "google") { 
        $models = @("gemini-2.5-flash", "gemini-2.5-flash-lite") 
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
        [string]$SystemPrompt
    )
    
    Write-Host "🤖 Agent Mode Activated" -ForegroundColor Cyan
    Write-Host "Task: $Task" -ForegroundColor Yellow
    Write-Host "---" -ForegroundColor DarkGray
    
    Write-Host "[1/3] Planning the task..." -ForegroundColor Cyan
    
    $context = Gather-Context "min"
    
    $planPrompt = @"
You are a PowerShell automation agent. Create a step-by-step plan for: "$Task"

Context:
$context

IMPORTANT: Return ONLY a valid JSON array, without additional text, without backticks, without explanations.

Return ONLY a JSON array with this EXACT structure:
[
  {
    "step": 1,
    "description": "Clear description of what this step does",
    "command": "Complete and executable PowerShell command",
    "risk": "low|medium|high"
  }
]

Important Guidelines:
1. Return ONLY the JSON, nothing else
2. Each PowerShell command must be COMPLETE and EXECUTABLE
3. ALWAYS close braces, parentheses and quotes
4. Use only standard and safe PowerShell commands
5. Mark as 'high' risk any operation that DELETES or DESTROYS data
6. Mark as 'medium' risk file creation/modification
7. Mark as 'low' risk read-only operations
8. Be conservative: when in doubt, mark as higher risk
9. Commands should be independently executable
10. Use absolute paths or environment variables

Valid JSON example:
[
  {
    "step": 1,
    "description": "Define downloads folder and list its contents",
    "command": "`$downloadsFolder = \"`$env:USERPROFILE\\Downloads\"; Write-Host \"Folder: `$downloadsFolder\"; Get-ChildItem -Path `$downloadsFolder -File | Select-Object Name, Length, LastWriteTime",
    "risk": "low"
  }
]

Now, create the plan for: "$Task"
"@
    
    Write-Host "Planning the task..." -ForegroundColor DarkGray
    $planJson = Call-API -Provider $Provider -Model $Model -Prompt $planPrompt `
        -SystemPrompt ($SystemPrompt + " You are a PowerShell expert. Respond ONLY with valid JSON.")
    
    if (-not $planJson) {
        Write-Host "❌ Planning failed" -ForegroundColor Red
        return
    }
    
    $plan = Extract-JsonFromResponse -Response $planJson
    
    if (-not $plan) {
        Write-Host "❌ Unable to parse JSON plan" -ForegroundColor Red
        Write-Host "Response received:" -ForegroundColor Yellow
        Write-Host $planJson -ForegroundColor Gray
        return
    }


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
    
   
    Write-Host "[2/3] Execution confirmation" -ForegroundColor Cyan
    $confirmation = Read-Host "Execute plan? (O/N/Detailed) [N]"
    
    if ($confirmation -notmatch '^[OoYy]') {
        if ($confirmation -match '^[Dd]') {
            Invoke-DetailedAgentExecution -Plan $plan
        } else {
            Write-Host "❌ Execution cancelled" -ForegroundColor Yellow
            return
        }
    } else {
        Invoke-AutoAgentExecution -Plan $plan
    }
}
function Extract-JsonFromResponse {
    param([string]$Response)
    
   
    $cleanResponse = $Response.Trim()
    
  
    $cleanResponse = $cleanResponse -replace '^```(?:json)?\s*\n?', ''
    $cleanResponse = $cleanResponse -replace '\n?```$', ''
    $cleanResponse = $cleanResponse.Trim()
    
  
    try {
        Write-Host "Attempting JSON parsing (direct method)..." -ForegroundColor DarkGray
        return $cleanResponse | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Write-Host "⚠️  Direct method failed, trying extraction..." -ForegroundColor Yellow
        
        # Method 2: Search for JSON with regex
        $jsonPattern = '\[\s*\{[\s\S]*?\}\s*\]'
        $match = [regex]::Match($cleanResponse, $jsonPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
        
        if ($match.Success) {
            $jsonText = $match.Value
            
            # Clean further
            $jsonText = $jsonText -replace '^\s*\[\s*', '['
            $jsonText = $jsonText -replace '\s*\]\s*$', ']'
            $jsonText = $jsonText -replace '[\r\n]+', ' '
            $jsonText = $jsonText -replace '\s+', ' '
            
            try {
                return $jsonText | ConvertFrom-Json -ErrorAction Stop
            }
            catch {
                Write-Host "⚠️  Regex parsing failed, trying manual extraction..." -ForegroundColor Yellow
            }
        }
        
        # Method 3: Manual extraction
        $startChar = $cleanResponse.IndexOf('[')
        $endChar = $cleanResponse.LastIndexOf(']')
        
        if ($startChar -ge 0 -and $endChar -gt $startChar) {
            $possibleJson = $cleanResponse.Substring($startChar, $endChar - $startChar + 1)
            
          
            $possibleJson = $possibleJson -replace '``', ''
            $possibleJson = $possibleJson -replace '\\"', '"'
            $possibleJson = $possibleJson -replace '`\$', '$'
            
            try {
                return $possibleJson | ConvertFrom-Json -ErrorAction Stop
            }
            catch {
                Write-Host "❌ Final JSON extraction failed" -ForegroundColor Red
                Write-Host "Error: $_" -ForegroundColor Red
           
                Write-Host "`n🔍 DETAILED DEBUG:" -ForegroundColor Magenta
                Write-Host "Original response (first 100 chars):" -ForegroundColor Cyan
                Write-Host $Response.Substring(0, [Math]::Min(100, $Response.Length)) -ForegroundColor Gray
                Write-Host "`nClean response (first 100):" -ForegroundColor Cyan
                Write-Host $cleanResponse.Substring(0, [Math]::Min(100, $cleanResponse.Length)) -ForegroundColor Gray
                Write-Host "`nPossible JSON (first 100):" -ForegroundColor Cyan
                Write-Host $possibleJson.Substring(0, [Math]::Min(100, $possibleJson.Length)) -ForegroundColor Gray
            }
        }
        
        return $null
    }
}

function Invoke-AutoAgentExecution {
    param($Plan)
    
    Write-Host "[3/3] Automatic execution..." -ForegroundColor Cyan
    
    $successCount = 0
    $errorCount = 0
    
    foreach ($step in $Plan) {
        Write-Host "`n--- Step $($step.step)/$($Plan.Count) ---" -ForegroundColor DarkGray
        Write-Host "📝 $($step.description)" -ForegroundColor Cyan
        Write-Host "⚡ Command:" -ForegroundColor Yellow
        Write-Host $step.command -ForegroundColor Gray
        
        try {
         
            $output = Invoke-Expression $step.command -ErrorAction Stop 2>&1
            
            if ($output) {
                Write-Host "📤 Output:" -ForegroundColor Green
                $output | Out-Host
            }
            
            Write-Host "✓ Success" -ForegroundColor Green
            $successCount++
        }
        catch {
            Write-Host "❌ Error: " -NoNewline -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            
            $continue = Read-Host "Continue? (O/N) [N]"
            if ($continue -notmatch '^[OoYy]') {
                Write-Host "⏹️ Execution interrupted" -ForegroundColor Yellow
                return
            }
            $errorCount++
        }
        
        Start-Sleep -Milliseconds 500
    }
    
    Write-Host "`n--- Summary ---" -ForegroundColor DarkGray
    Write-Host "✅ Success: $successCount" -ForegroundColor Green
    Write-Host "❌ Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Gray" })
    Write-Host "📊 Total: $($Plan.Count) steps" -ForegroundColor Cyan
}

function Invoke-DetailedAgentExecution {
    param($Plan)
    
    Write-Host "[3/3] Step-by-step execution..." -ForegroundColor Cyan
    
    $successCount = 0
    $errorCount = 0
    $skippedCount = 0
    
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
        
        switch ($choice.ToUpper()) {
            'E' {
             
                try {
                    Write-Host "🔄 Executing..." -ForegroundColor Cyan
                    $output = Invoke-Expression $step.command -ErrorAction Stop 2>&1
                    
                    if ($output) {
                        Write-Host "📤 Output:" -ForegroundColor Green
                        $output | Out-Host
                    }
                    
                    Write-Host "✓ Step $($step.step) completed" -ForegroundColor Green
                    $successCount++
                }
                catch {
                    Write-Host "❌ Error: " -NoNewline -ForegroundColor Red
                    Write-Host $_.Exception.Message -ForegroundColor Red
                    
                    $continue = Read-Host "Continue despite error? (O/N) [N]"
                    if ($continue -notmatch '^[OoYy]') {
                        Write-Host "⏹️ Execution interrupted" -ForegroundColor Yellow
                        return
                    }
                    $errorCount++
                }
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
                    try {
                        Write-Host "🔄 Executing modified command..." -ForegroundColor Cyan
                        $output = Invoke-Expression $newCommand -ErrorAction Stop 2>&1
                        
                        if ($output) {
                            Write-Host "📤 Output:" -ForegroundColor Green
                            $output | Out-Host
                        }
                        
                        Write-Host "✓ Step $($step.step) completed" -ForegroundColor Green
                        $successCount++
                    }
                    catch {
                        Write-Host "❌ Error: " -NoNewline -ForegroundColor Red
                        Write-Host $_.Exception.Message -ForegroundColor Red
                        
                        $continue = Read-Host "Continue despite error? (O/N) [N]"
                        if ($continue -notmatch '^[OoYy]') {
                            Write-Host "⏹️ Execution interrupted" -ForegroundColor Yellow
                            return
                        }
                        $errorCount++
                    }
                } else {
                    Write-Host "⚠️ Modification cancelled" -ForegroundColor Yellow
                    $skippedCount++
                }
            }
            'A' {
                Write-Host "⏹️ Execution stopped" -ForegroundColor Yellow
                return
            }
            default {
           
                try {
                    Write-Host "🔄 Executing..." -ForegroundColor Cyan
                    $output = Invoke-Expression $step.command -ErrorAction Stop 2>&1
                    
                    if ($output) {
                        Write-Host "📤 Output:" -ForegroundColor Green
                        $output | Out-Host
                    }
                    
                    Write-Host "✓ Step $($step.step) completed" -ForegroundColor Green
                    $successCount++
                }
                catch {
                    Write-Host "❌ Error: " -NoNewline -ForegroundColor Red
                    Write-Host $_.Exception.Message -ForegroundColor Red
                    
                    $continue = Read-Host "Continue despite error? (O/N) [N]"
                    if ($continue -notmatch '^[OoYy]') {
                        Write-Host "⏹️ Execution interrupted" -ForegroundColor Yellow
                        return
                    }
                    $errorCount++
                }
            }
        }
        
        # Pause between steps
        if ($step.step -lt $Plan.Count) {
            Start-Sleep -Milliseconds 500
        }
    }
    
    Write-Host "`n--- Summary ---" -ForegroundColor DarkGray
    Write-Host "✅ Success: $successCount" -ForegroundColor Green
    Write-Host "❌ Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Gray" })
    Write-Host "⏭️ Skipped: $skippedCount" -ForegroundColor Yellow
    Write-Host "📊 Total: $($Plan.Count) steps" -ForegroundColor Cyan
}

function Call-API {
    param(
        $provider,
        $model,
        $prompt,
        $systemPrompt = "You are a helpful AI assistant for the command line. Provide concise, accurate answers. When writing code or commands, ensure they are correct and safe.",
        $temperature = 0.7,
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
    Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║" -NoNewline -ForegroundColor Cyan
    Write-Host "                     ask - v$VERSION" -NoNewline -ForegroundColor White
    Write-Host "                    ║" -ForegroundColor Cyan
    Write-Host "║" -NoNewline -ForegroundColor Cyan
    Write-Host "     AI-powered shell assistant for PowerShell" -NoNewline -ForegroundColor White
    Write-Host "     ║" -ForegroundColor Cyan
    Write-Host "║" -NoNewline -ForegroundColor Cyan
    Write-Host "       don't grep. don't awk. just ask" -NoNewline -ForegroundColor Magenta
    Write-Host "        ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📖 DESCRIPTION" -ForegroundColor Yellow
    Write-Host "   An intelligent CLI assistant that uses AI to help with PowerShell tasks,"
    Write-Host "   scripting, and system administration. Supports multiple AI providers."
    Write-Host ""
    
    Write-Host "🚀 BASIC USAGE" -ForegroundColor Yellow
    Write-Host "   ask [OPTIONS] [PROMPT]              # Single question mode"
    Write-Host "   ask [OPTIONS]                       # Interactive mode"
    Write-Host "   COMMAND | ask [OPTIONS] [PROMPT]    # Pipe input to ask"
    Write-Host ""
    
    Write-Host "🎯 MODES" -ForegroundColor Yellow
    Write-Host "   Normal Mode   Answer questions, explain code, provide commands"
    Write-Host "   Agent Mode    Plan and execute complex multi-step tasks"
    Write-Host ""
    
    Write-Host "🔧 OPTIONS" -ForegroundColor Yellow
    Write-Host "   -Agent                 Enable agent mode for complex task planning"
    Write-Host "   -Provider PROVIDER     AI provider to use"
    Write-Host "                          [default: anthropic]"
    Write-Host "   -Model MODEL           Specific model to use (defaults per provider)"
    Write-Host "   -Context LEVEL         System context to include:"
    Write-Host "                          none    - No system information"
    Write-Host "                          min     - Basic info only"
    Write-Host "                          auto    - Smart context (default)"
    Write-Host "                          full    - Detailed system information"
    Write-Host "   -SystemPrompt TEXT     Custom system prompt for AI"
    Write-Host "   -ListModels            List available models for the provider"
    Write-Host ""
    
    Write-Host "🤖 SUPPORTED PROVIDERS" -ForegroundColor Yellow
    Write-Host "   anthropic    Claude models (claude-3-sonnet, claude-3-opus, claude-3-haiku)"
    Write-Host "   openai       GPT models (gpt-4o, gpt-4o-mini, gpt-4-turbo)"
    Write-Host "   openrouter   Unified API for multiple providers"
    Write-Host "   google       Gemini models (gemini-2.5-flash, gemini-2.5-flash-lite)"
    Write-Host "   deepseek     DeepSeek models (deepseek-chat, deepseek-coder)"
    Write-Host ""
    
    Write-Host "🔑 API KEY MANAGEMENT" -ForegroundColor Yellow
    Write-Host "   ask keys set provider         Set API key for a provider"
    Write-Host "   ask keys list                 List all configured API keys"
    Write-Host "   ask keys remove provider      Remove API key for a provider"
    Write-Host "   ask keys path                 Show location of keys file"
    Write-Host ""
    Write-Host "   Keys are stored in: $KEYS_FILE" -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "📝 EXAMPLES" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   # First time setup" -ForegroundColor Cyan
    Write-Host "   ask keys set anthropic"
    Write-Host ""
    Write-Host "   # Basic questions" -ForegroundColor Cyan
    Write-Host "   ask 'how do I list services in Windows?'"
    Write-Host "   ask 'explain this PowerShell script' < script.ps1"
    Write-Host "   Get-Process | ask 'which processes are using the most memory?'"
    Write-Host ""
    Write-Host "   # With different providers" -ForegroundColor Cyan
    Write-Host "   ask -Provider openai 'write a function to backup files'"
    Write-Host "   ask -Provider google -Model gemini-2.5-flash 'optimize this SQL query'"
    Write-Host ""
    Write-Host "   # Agent mode (complex tasks)" -ForegroundColor Cyan
    Write-Host "   ask -agent 'find and optimize all PNG files in ./images'"
    Write-Host "   ask -agent 'clean up temp files older than 30 days'"
    Write-Host "   ask -agent 'organize my downloads folder by file type'"
    Write-Host "   ask -agent 'create a backup script for my documents'"
    Write-Host ""
    Write-Host "   # Context and customization" -ForegroundColor Cyan
    Write-Host "   ask -Context full 'what can you tell me about my system?'"
    Write-Host "   ask -SystemPrompt 'You are a PowerShell security expert' 'audit my system'"
    Write-Host ""
    
    Write-Host "🎪 AGENT MODE FEATURES" -ForegroundColor Yellow
    Write-Host "   • Plans complex tasks step by step"
    Write-Host "   • Executes PowerShell commands safely"
    Write-Host "   • Asks for confirmation before risky operations"
    Write-Host "   • Provides risk assessment for each step"
    Write-Host "   • Allows step-by-step or automatic execution"
    Write-Host ""
    
    Write-Host "⚙️  CONFIGURATION" -ForegroundColor Yellow
    Write-Host "   Configuration directory: $CONFIG_DIR" -ForegroundColor Green
    Write-Host "   Cache directory: $CACHE_DIR" -ForegroundColor Green
    Write-Host "   Keys file: $KEYS_FILE" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "💡 TIPS" -ForegroundColor Yellow
    Write-Host "   • Use quotes for multi-word prompts"
    Write-Host "   • Pipe output to ask for analysis"
    Write-Host "   • Start with -Context auto for better responses"
    Write-Host "   • Use -ListModels to see available options"
    Write-Host "   • Agent mode works best for multi-step system tasks"
    Write-Host ""
    
    Write-Host "🔗 GETTING API KEYS" -ForegroundColor Yellow
    Write-Host "   Anthropic:   https://console.anthropic.com/" -ForegroundColor Green
    Write-Host "   OpenAI:      https://platform.openai.com/api-keys" -ForegroundColor Green
    Write-Host "   OpenRouter:  https://openrouter.ai/keys" -ForegroundColor Green
    Write-Host "   Google:      https://aistudio.google.com/apikey" -ForegroundColor Green
    Write-Host "   DeepSeek:    https://platform.deepseek.com/" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "🆘 NEED MORE HELP?" -ForegroundColor Yellow
    Write-Host "   Visit: https://github.com/elias-ba/ask" -ForegroundColor Cyan
    Write-Host "   Report issues with detailed descriptions"
    Write-Host ""
    Write-Host "© $((Get-Date).Year) $AUTHOR - AI-powered CLI assistant" -ForegroundColor Magenta
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
        Get_models $Provider
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
        
        Invoke-AgentMode -Task $userPrompt -Provider $Provider -Model $Model `
            -SystemPrompt $SystemPrompt
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
