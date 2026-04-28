<#
.SYNOPSIS
    Check status of OpenClaw local backend services — Yggdrasil
#>

$BackendDir  = $PSScriptRoot
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ConfigDir   = "$ProjectRoot\.openclaw"

Write-Host ""
Write-Host "=== OpenClaw Local Backend Status ===" -ForegroundColor Cyan
Write-Host ""

# -- Ollama --
Write-Host "Ollama" -ForegroundColor Yellow
$ollamaProc = Get-Process ollama -ErrorAction SilentlyContinue
if ($ollamaProc) {
    Write-Host "  [RUNNING]  PID $($ollamaProc.Id)  ->  http://localhost:11434" -ForegroundColor Green
    try {
        $tags  = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 3
        $names = ($tags.models | ForEach-Object { $_.name }) -join ", "
        Write-Host "  Models: $names" -ForegroundColor DarkGray
    } catch {
        Write-Host "  API not responding yet (still starting up)." -ForegroundColor DarkYellow
    }
} else {
    Write-Host "  [STOPPED]" -ForegroundColor Red
}

Write-Host ""

# -- ComfyUI --
Write-Host "ComfyUI" -ForegroundColor Yellow
$comfyConn = Get-NetTCPConnection -LocalPort 8188 -State Listen -ErrorAction SilentlyContinue
if ($comfyConn) {
    Write-Host "  [RUNNING]  PID $($comfyConn.OwningProcess)  ->  http://localhost:8188" -ForegroundColor Green
} else {
    Write-Host "  [STOPPED]" -ForegroundColor Red
}

Write-Host ""

# -- OpenClaw config --
Write-Host "OpenClaw config  ($ConfigDir)" -ForegroundColor Yellow
$configFile = "$ConfigDir\openclaw.json"
$envFile    = "$ConfigDir\.env"

if (Test-Path $configFile) {
    Write-Host "  [PRESENT]  openclaw.json" -ForegroundColor Green
} else {
    Write-Host "  [MISSING]  openclaw.json  ->  run .\backend\setup.ps1" -ForegroundColor Red
}

if (Test-Path $envFile) {
    Write-Host "  [PRESENT]  .env" -ForegroundColor Green
} else {
    Write-Host "  [MISSING]  .env  ->  run .\backend\setup.ps1" -ForegroundColor Red
}

# -- SD model --
Write-Host ""
Write-Host "SD 1.5 model" -ForegroundColor Yellow
$ModelDir = "$BackendDir\comfyui\ComfyUI\models\checkpoints"
if (Test-Path $ModelDir) {
    $models = Get-ChildItem $ModelDir -Filter "*.safetensors" -ErrorAction SilentlyContinue
    if ($models) {
        foreach ($m in $models) {
            $sizeMB = [math]::Round($m.Length / 1MB)
            Write-Host "  [PRESENT]  $($m.Name)  (${sizeMB} MB)" -ForegroundColor Green
        }
    } else {
        Write-Host "  [MISSING]  No .safetensors in checkpoints/" -ForegroundColor Red
        Write-Host "             Image generation disabled until a model is placed there." -ForegroundColor Yellow
    }
} else {
    Write-Host "  [MISSING]  ComfyUI not installed  ->  run .\backend\setup.ps1" -ForegroundColor Red
}

Write-Host ""
