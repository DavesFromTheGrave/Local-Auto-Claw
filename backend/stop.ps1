<#
.SYNOPSIS
    Stop OpenClaw local backend services — Yggdrasil
#>

Write-Host ""
Write-Host "=== Stopping OpenClaw Local Backend ===" -ForegroundColor Cyan
Write-Host ""

# -- Ollama --
Write-Host "[1/2] Ollama" -ForegroundColor Yellow
$ollamaProc = Get-Process ollama -ErrorAction SilentlyContinue
if ($ollamaProc) {
    Stop-Process -Name ollama -Force
    Write-Host "  Stopped (was PID $($ollamaProc.Id))." -ForegroundColor Green
} else {
    Write-Host "  Not running." -ForegroundColor DarkGray
}

# -- ComfyUI --
Write-Host "[2/2] ComfyUI" -ForegroundColor Yellow
$comfyConn = Get-NetTCPConnection -LocalPort 8188 -State Listen -ErrorAction SilentlyContinue
if ($comfyConn) {
    $procId = $comfyConn.OwningProcess
    Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
    Write-Host "  Stopped (was PID $procId)." -ForegroundColor Green
} else {
    Write-Host "  Not running." -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Done." -ForegroundColor Cyan
Write-Host ""
