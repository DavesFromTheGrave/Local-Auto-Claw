<#
.SYNOPSIS
    Start OpenClaw local backend services — Yggdrasil
    Starts Ollama and ComfyUI if not already running.
#>

$BackendDir  = $PSScriptRoot
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ComfyDir    = "$BackendDir\comfyui"
$ComfyPython = "$ComfyDir\python_embeded\python.exe"
$ComfyMain   = "$ComfyDir\ComfyUI\main.py"
$ConfigDir   = "$ProjectRoot\.openclaw"

# Set for this session and any child processes so OpenClaw never looks at C:.
$env:OPENCLAW_STATE_DIR = $ConfigDir

Write-Host ""
Write-Host "=== Starting OpenClaw Local Backend ===" -ForegroundColor Cyan
Write-Host ""

# -- Ollama --
Write-Host "[1/2] Ollama" -ForegroundColor Yellow

$ollamaProc = Get-Process ollama -ErrorAction SilentlyContinue
if ($ollamaProc) {
    Write-Host "  Already running (PID $($ollamaProc.Id))." -ForegroundColor Green
} else {
    if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
        Write-Host "  ERROR: Ollama not installed. Run .\backend\setup.ps1 first." -ForegroundColor Red
        exit 1
    }
    Start-Process ollama -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -Seconds 2
    Write-Host "  Started -> http://localhost:11434" -ForegroundColor Green
}

# -- ComfyUI --
Write-Host "[2/2] ComfyUI" -ForegroundColor Yellow

$comfyPort = Get-NetTCPConnection -LocalPort 8188 -State Listen -ErrorAction SilentlyContinue
if ($comfyPort) {
    Write-Host "  Already running (port 8188)." -ForegroundColor Green
} else {
    if (-not (Test-Path $ComfyPython)) {
        Write-Host "  ERROR: ComfyUI not found at: $ComfyDir" -ForegroundColor Red
        Write-Host "  Run .\backend\setup.ps1 first." -ForegroundColor Yellow
        exit 1
    }
    Start-Process -FilePath $ComfyPython `
        -ArgumentList "`"$ComfyMain`" --port 8188" `
        -WorkingDirectory "$ComfyDir\ComfyUI" `
        -WindowStyle Minimized
    Write-Host "  Starting -> http://localhost:8188" -ForegroundColor Green
    Write-Host "  (Allow 15-20 seconds to be ready on first launch.)" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Services" -ForegroundColor Cyan
Write-Host "  Ollama  : http://localhost:11434" -ForegroundColor White
Write-Host "  ComfyUI : http://localhost:8188" -ForegroundColor White
Write-Host ""
Write-Host "Launch OpenClaw (from this terminal):" -ForegroundColor Cyan
Write-Host "  cd $ProjectRoot" -ForegroundColor White
Write-Host "  node openclaw.mjs" -ForegroundColor White
Write-Host ""
Write-Host "  OPENCLAW_STATE_DIR is already set for this session." -ForegroundColor DarkGray
Write-Host "  New terminal? Re-run start.ps1 or set it manually:" -ForegroundColor DarkGray
Write-Host "  `$env:OPENCLAW_STATE_DIR = '$ConfigDir'" -ForegroundColor DarkGray
Write-Host ""
