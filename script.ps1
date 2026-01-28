# ==========================================
#  ABDUZNIK'S AI PROJECT ARCHITECT
#  Current Version: v1.0
# ==========================================

function ai-pro-arch {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("Init", "Fix", "Explain")]
        [string]$Mode,

        [Parameter(Mandatory=$true)]
        [string]$Input,

        [Parameter(Mandatory=$false)]
        [string]$File
    )

    # --- CONFIGURATION ---
    $ToolVersion = "1.0"
    
    # Priority: Smartest (Gemini 3) -> High Bandwidth (Gemma 3) -> Fallback (Flash)
    $ModelList = @("gemini-3-flash-preview", "gemini-2.5-flash", "gemini-2.5-flash-lite", "gemma-3-27b-it")
    # ---------------------

    Write-Host "Abduznik AI Architect [v$ToolVersion]" -ForegroundColor Magenta
    Write-Host "Mode: $Mode" -ForegroundColor Cyan

    # 1. Validation
    if ($Mode -eq "Fix" -and -not $File) {
        Write-Host "Error: -File parameter is mandatory for Fix mode." -ForegroundColor Red
        return
    }

    # 2. Prompt Construction
    $prompt = ""
    $systemContext = ""

    if ($Mode -eq "Init") {
        # Init Mode: Scaffolding
        # Goal: Get a strict JSON array of shell commands
        $template = 'Task: Project Scaffolding. User Goal: "{0}". OS: "{1}". Return ONLY a JSON object with a single key "commands" containing an array of shell strings. Example: {{"commands": ["mkdir project", "cd project"]}}. Do NOT use markdown blocks.'
        $prompt = $template -f $Input, $env:OS
    }
    elseif ($Mode -eq "Fix") {
        # Fix Mode: Patching
        # Goal: Get the corrected file content only
        if (Test-Path $File) {
            $content = Get-Content $File -Raw
        } else {
            Write-Host "Error: File '$File' not found." -ForegroundColor Red
            return
        }
        $template = 'Task: Fix Code. Issue: "{0}". File Content: "{1}". Return ONLY the corrected complete file content. Ensure it is ready to be written to disk. Do NOT use markdown blocks.'
        $prompt = $template -f $Input, $content
    }
    elseif ($Mode -eq "Explain") {
        # Explain Mode: Explanation
        # Goal: Plain text explanation
        $template = 'Task: Explain Concept/Code. Context: "{0}". Keep it concise and technical.'
        $prompt = $template -f $Input
    }

    # 3. AI Execution Loop (Multi-model Fallback)
    $aiOutput = $null
    $success = $false

    foreach ($model in $ModelList) {
        Write-Host "   -> Attempting with model: $model..." -ForegroundColor DarkGray
        
        try {
            # Compatibility: Check for Docker shim path first, then global path
            if (Test-Path "/usr/local/bin/gemini") {
                $currentRun = & /usr/local/bin/gemini $prompt --model $model 2>&1 | Out-String
            } else {
                $currentRun = & gemini $prompt --model $model 2>&1 | Out-String
            }
        } catch {
            $currentRun = "Error: " + $_.Exception.Message
        }

        # Cleanup Warnings (Shim specific)
        if ($currentRun -match "Both GOOGLE_API_KEY and GEMINI_API_KEY are set") {
            $currentRun = $currentRun -replace "Both GOOGLE_API_KEY and GEMINI_API_KEY are set\. Using GOOGLE_API_KEY\.", ""
        }
        $currentRun = $currentRun.Trim()

        # Check for Errors
        if ($currentRun -match "429" -or $currentRun -match "exhausted" -or $currentRun -match "Quota") {
            Write-Host "      [!] Quota hit on $model. Pausing 3s..." -ForegroundColor Yellow
            Start-Sleep -Seconds 3
            continue
        } elseif ($currentRun -match "Error:" -or $currentRun -match "Exception") {
            Write-Host "      [DEBUG] $currentRun" -ForegroundColor Red
            Write-Host "      [!] Generic error on $model. Switching..." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
            continue
        }

        # Success Validation based on Mode
        if ($Mode -eq "Init") {
            # We need JSON
            if ($currentRun -match "\{.*\}") {
                $aiOutput = $currentRun
                $success = $true
                break
            }
        } else {
            # Fix/Explain just need text
            if (-not [string]::IsNullOrWhiteSpace($currentRun)) {
                $aiOutput = $currentRun
                $success = $true
                break
            }
        }
    }

    if (-not $success) {
        Write-Host "!! Error: All AI models failed to generate a response." -ForegroundColor Red
        return
    }

    # 4. Result Processing
    
    # Common Cleanup: Remove Markdown code blocks if present
    $cleanOutput = $aiOutput -replace '^```[a-z]*', '' -replace '```$', '' -replace '^\s*```', '' -replace '```\s*$', ''
    $cleanOutput = $cleanOutput.Trim()

    if ($Mode -eq "Init") {
        try {
            $jsonObj = $cleanOutput | ConvertFrom-Json
            $commands = $jsonObj.commands
            
            Write-Host "Generated Plan:" -ForegroundColor Green
            foreach ($cmd in $commands) {
                Write-Host "  > $cmd" -ForegroundColor Gray
            }
            
            $confirm = Read-Host "Execute these commands? (y/n)"
            if ($confirm -eq 'y') {
                foreach ($cmd in $commands) {
                    Write-Host "Running: $cmd" -ForegroundColor Cyan
                    # We use Invoke-Expression to handle the command strings dynamically
                    # This is necessary as the AI might return full shell commands
                    Invoke-Expression $cmd
                }
                Write-Host "Scaffolding Complete." -ForegroundColor Green
            } else {
                Write-Host "Aborted." -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Error parsing AI response for scaffolding." -ForegroundColor Red
            Write-Host "Raw Output: $cleanOutput" -ForegroundColor DarkGray
        }
    }
    elseif ($Mode -eq "Fix") {
        Write-Host "Patching file: $File" -ForegroundColor Cyan
        
        # Backup original
        Copy-Item $File "$File.bak" -Force
        Write-Host "Backup created at $File.bak" -ForegroundColor DarkGray
        
        Set-Content -Path $File -Value $cleanOutput
        Write-Host "File updated successfully." -ForegroundColor Green
    }
    elseif ($Mode -eq "Explain") {
        Write-Host "`n--- Explanation ---" -ForegroundColor White
        Write-Host $cleanOutput -ForegroundColor Gray
        Write-Host "-------------------" -ForegroundColor White
    }
}

# Standalone execution support
if ($MyInvocation.InvocationName -ne '.' -and $MyInvocation.InvocationName -ne '&') {
    # If run directly (not sourced), pass all args
    ai-pro-arch @args
}
