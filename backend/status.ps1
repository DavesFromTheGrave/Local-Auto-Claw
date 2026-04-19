<#
.SYNOPSIS
    Check status of OpenClaw local backend services — Yggdrasil
#>

$ProjectRoot = "C:\The-Ossuary\Revenant-Systems\Projects\Local-Auto-Claw"
$ConfigDir   = "$env:USERPROFILE\.openclaw"

Write-Host ""
Write-Host "=== OpenClaw Local Backend Status ===" -ForegroundColor Cyan
Write-Host ""

# -- Ollama --
Write-Host "Ollama" -ForegroundColor Yellow
$ollamaProc = Get-Process ollama -ErrorAction SilentlyContinue
if ($ollamaProc) {
    Write-Host "  [RUNNING]  PID $($ollamaProc.Id)  ->  http://localhost:11434" -ForegroundColor Green
    try {
        $tags   = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 3
        $names  = ($tags.models | ForEach-Object { $_.name }) -join ", "
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
Write-Host "OpenClaw config" -ForegroundColor Yellow
$configFile = "$ConfigDir\openclaw.json"
$envFile    = "$ConfigDir\.env"

if (Test-Path $configFile) {
    Write-Host "  [PRESENT]  $configFile" -ForegroundColor Green
} else {
    Write-Host "  [MISSING]  $configFile" -ForegroundColor Red
    Write-Host "             Run .\backend\setup.ps1 to generate it." -ForegroundColor Yellow
}

if (Test-Path $envFile) {
    Write-Host "  [PRESENT]  $envFile" -ForegroundColor Green
} else {
    Write-Host "  [MISSING]  $envFile" -ForegroundColor Red
}

# -- SD model --
Write-Host ""
Write-Host "SD 1.5 model" -ForegroundColor Yellow
$ModelDir = "$ProjectRoot\backend\comfyui\ComfyUI\models\checkpoints"
if (Test-Path $ModelDir) {
    $models = Get-ChildItem $ModelDir -Filter "*.safetensors" -ErrorAction SilentlyContinue
    if ($models) {
        foreach ($m in $models) {
            $sizeMB = [math]::Round($m.Length / 1MB)
            Write-Host "  [PRESENT]  $($m.Name)  (${sizeMB} MB)" -ForegroundColor Green
        }
    } else {
        Write-Host "  [MISSING]  No .safetensors in $ModelDir" -ForegroundColor Red
        Write-Host "             Image generation disabled until a model is placed there." -ForegroundColor Yellow
    }
} else {
    Write-Host "  [MISSING]  ComfyUI not installed. Run .\backend\setup.ps1 first." -ForegroundColor Red
}

Write-Host ""
