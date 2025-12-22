# ask.ps1 - AI-powered shell assistant for PowerShell
# Designed by Malick DIENE

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

    [ValidateSet("none","min","auto","full")]
    [string]$Context = "auto",

    [string]$SystemPrompt
)


# Configuration
$VERSION = "1.0.0"
$AUTHOR = "Malick DIENE"
$CONFIG_DIR = "$env:USERPROFILE\.config\ask"
$CACHE_DIR = "$env:USERPROFILE\.cache\ask"
$KEYS_FILE = "$CONFIG_DIR\keys.env"

# Defaults
$DEFAULT_PROVIDER = "anthropic"
$DEFAULT_MODELS = @{
    anthropic = "claude-sonnet-4-5-20250929"
    openai = "gpt-4o"
    openrouter = "anthropic/claude-sonnet-4-5"
    google = "gemini-2.5-flash"
    deepseek = "deepseek-chat"
}

# Initialize configuration
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

# Load API keys from file
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

# Manage API keys
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

# Check API key for provider
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

# Get API URL for provider
function Get-APIUrl {
    param($provider)
    
    if ($provider -eq "anthropic") { return "https://api.anthropic.com/v1/messages" }
    elseif ($provider -eq "openai") { return "https://api.openai.com/v1/chat/completions" }
    elseif ($provider -eq "openrouter") { return "https://openrouter.ai/api/v1/chat/completions" }
    elseif ($provider -eq "google") { return "https://generativelanguage.googleapis.com/v1beta/models" }
    elseif ($provider -eq "deepseek") { return "https://api.deepseek.com/v1/chat/completions" }
}

# List available models
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

# Gather context information
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

# Call API with proper error handling
function Call-API {
    param(
        $provider,
        $model,
        $prompt,
        $systemPrompt = "You are a helpful AI assistant for the command line. Provide concise, accurate answers. When writing code or commands, ensure they are correct and safe.",
        $temperature = 1.0,
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
            # Google Gemini API
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
            } | ConvertTo-Json -Depth 10
            
            $response = Invoke-RestMethod -Uri $fullUrl -Method Post -Headers $headers -Body $body
            
            # Check for errors
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
            # Case 1: HttpWebResponse (classic PS 5.1)
            if ($resp -is [System.Net.HttpWebResponse]) {
                $stream = $resp.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($stream)
                $body = $reader.ReadToEnd()
            }
            # Case 2: HttpResponseMessage (newer handlers)
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

    # Friendly 429 hint
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
    Write-Host "Designed by $AUTHOR" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "    ask [OPTIONS] [PROMPT]"
    Write-Host "    ask [OPTIONS]              # Interactive mode"
    Write-Host ""
    Write-Host "OPTIONS:" -ForegroundColor Yellow
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
    Write-Host "    # First time setup"
    Write-Host "    ask keys set anthropic"
    Write-Host ""
    Write-Host "    # Basic usage"
    Write-Host "    ask 'how do I list services in Windows?'"
    Write-Host "    ask -Provider openai 'explain this PowerShell script'"
    Write-Host "    ask -Provider openai -Model gemini-2.5-flash 'how do I list services in Windows?'"
    Write-Host ""
    Write-Host "    # With context"
    Write-Host "    Get-ChildItem | ask -Context full 'what files do I have?'"
}

# Main execution
function Main {
    # If first argument is "keys", handle key management
    if ($Arguments.Count -gt 0 -and $Arguments[0] -eq "keys") {
    Initialize-Config

    $action   = if ($Arguments.Count -gt 1) { $Arguments[1] } else { $null }
    $provider = if ($Arguments.Count -gt 2) { $Arguments[2] } else { $null }
    $key      = if ($Arguments.Count -gt 3) { $Arguments[3] } else { $null }

    Manage-Keys -Action $action -Provider $provider -Key $key
    return
}

    
    # Parse parameters
    if ($Help) {
        Show-Help
        return
    }
    
    # Initialize config
    Initialize-Config
    
    # Auto-select default model if not specified
    if ([string]::IsNullOrEmpty($Model)) {
        $Model = $DEFAULT_MODELS[$Provider]
    }
    
    # Check API key
    Check-APIKey $Provider
    
    # List models if requested
    if ($ListModels) {
        Get-Models $Provider
        return
    }
    
    # Get prompt from arguments if not provided via -Prompt
    $userPrompt = ""
    if ([string]::IsNullOrEmpty($userPrompt) -and $Arguments.Count -gt 0) {
        $userPrompt = $Arguments -join " "
    }
    

    $pipedInput = ""
    if ($PipelineInput) {
    $pipedInput = $PipelineInput | Out-String
    }
    

    if (-not [string]::IsNullOrEmpty($pipedInput)) {
        if (-not [string]::IsNullOrEmpty($userPrompt)) {
            $userPrompt = "Input:`n$pipedInput`n`nQuestion: $userPrompt"
        } else {
            $userPrompt = $pipedInput
        }
    }
    
    # Add context if requested
    if ($Context -ne "none" -and -not [string]::IsNullOrEmpty($userPrompt)) {
        $ctx = Gather-Context $Context
        if (-not [string]::IsNullOrEmpty($ctx)) {
            $userPrompt = "Context about my system:`n$ctx`n`nQuestion: $userPrompt"
        }
    }
    
    # Call API
    if (-not [string]::IsNullOrEmpty($userPrompt)) {
        
        $response = Call-API -Provider $Provider -Model $Model -Prompt $userPrompt `
             -SystemPrompt $SystemPrompt
        
        if ($response) {
            Write-Host $response
        }
    } else {
        # Interactive mode placeholder
        Write-Host "Interactive mode not yet implemented" -ForegroundColor Cyan
        Write-Host "Please provide a prompt. Example:" -ForegroundColor Yellow
        Write-Host "  ask 'your question here'" -ForegroundColor Green
    }
}

# Main execution block
try {
    # Execute main function
    Main
}
catch {
    Write-Host "Error: " -NoNewline -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "For help: ask -Help" -ForegroundColor Yellow
}
