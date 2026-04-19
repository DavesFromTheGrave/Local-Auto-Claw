<#
.SYNOPSIS
    OpenClaw local backend setup — Yggdrasil
    One-time setup: Ollama + ComfyUI portable + SD 1.5 model + OpenClaw config
.NOTES
    GPU:   RTX 3070 Ti (8GB VRAM, CUDA)
    Shell: PowerShell
    Run from project root. Run as Administrator for winget installs.
#>

$ErrorActionPreference = "Stop"

$ProjectRoot = "C:\The-Ossuary\Revenant-Systems\Projects\Local-Auto-Claw"
$BackendDir  = "$ProjectRoot\backend"
$ComfyDir    = "$BackendDir\comfyui"
$WorkflowDir = "$BackendDir\workflows"
$ConfigDir   = "$env:USERPROFILE\.openclaw"

Write-Host ""
Write-Host "+==========================================+" -ForegroundColor Cyan
Write-Host "|  OpenClaw Local Backend Setup            |" -ForegroundColor Cyan
Write-Host "|  Yggdrasil  |  RTX 3070 Ti  |  CUDA     |" -ForegroundColor Cyan
Write-Host "+==========================================+" -ForegroundColor Cyan
Write-Host ""

# ==========================================================================
# 1. OLLAMA
# ==========================================================================
Write-Host "[1/4] Ollama" -ForegroundColor Yellow

if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Host "  Installing via winget..." -ForegroundColor Gray
    winget install --id Ollama.Ollama --silent --accept-package-agreements --accept-source-agreements
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("PATH", "User")
    Write-Host "  Ollama installed." -ForegroundColor Green
} else {
    Write-Host "  Already installed." -ForegroundColor Green
}

$ollamaRunning = Get-Process ollama -ErrorAction SilentlyContinue
if (-not $ollamaRunning) {
    Write-Host "  Starting Ollama service..." -ForegroundColor Gray
    Start-Process ollama -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -Seconds 3
}

Write-Host "  Pulling models (first run: allow 20-40 min depending on connection)..." -ForegroundColor Gray

$models = @(
    @{ id = "llama3.1:8b";       label = "General chat    (8B,  ~5GB)" },
    @{ id = "qwen2.5-coder:7b";  label = "Code generation (7B,  ~5GB)" },
    @{ id = "nomic-embed-text";  label = "Memory embeddings     (~300MB)" }
)

foreach ($m in $models) {
    Write-Host "  -> $($m.label)" -ForegroundColor DarkGray
    ollama pull $m.id
}

Write-Host "  Ollama models ready." -ForegroundColor Green

# ==========================================================================
# 2. COMFYUI (portable NVIDIA build)
# ==========================================================================
Write-Host ""
Write-Host "[2/4] ComfyUI" -ForegroundColor Yellow

if (-not (Test-Path "$ComfyDir\ComfyUI\main.py")) {

    if (-not (Get-Command 7z -ErrorAction SilentlyContinue)) {
        Write-Host "  Installing 7-Zip..." -ForegroundColor Gray
        winget install --id 7zip.7zip --silent --accept-package-agreements --accept-source-agreements
        $env:PATH += ";C:\Program Files\7-Zip"
    }

    Write-Host "  Fetching latest ComfyUI release info from GitHub..." -ForegroundColor Gray
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/comfyanonymous/ComfyUI/releases/latest" -UseBasicParsing
    $asset   = $release.assets | Where-Object { $_.name -like "*portable*nvidia*" } | Select-Object -First 1

    if (-not $asset) {
        Write-Host ""
        Write-Host "  ERROR: Could not find ComfyUI portable NVIDIA asset in latest release." -ForegroundColor Red
        Write-Host "  Download manually: https://github.com/comfyanonymous/ComfyUI/releases/latest" -ForegroundColor Yellow
        Write-Host "  Extract to: $ComfyDir" -ForegroundColor Yellow
        Write-Host "  (Directory must contain ComfyUI\main.py)" -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }

    $archive = "$env:TEMP\$($asset.name)"
    Write-Host "  Downloading $($asset.name) (~2-3 GB)..." -ForegroundColor Gray
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $archive -UseBasicParsing

    Write-Host "  Extracting..." -ForegroundColor Gray
    New-Item -ItemType Directory -Path $BackendDir -Force | Out-Null
    & 7z x $archive "-o$BackendDir" -y | Out-Null

    $extracted = Get-ChildItem $BackendDir -Directory | Where-Object { $_.Name -like "ComfyUI*" } | Select-Object -First 1
    if ($extracted -and $extracted.Name -ne "comfyui") {
        Rename-Item $extracted.FullName "comfyui"
    }

    Remove-Item $archive -Force -ErrorAction SilentlyContinue
    Write-Host "  ComfyUI extracted to: $ComfyDir" -ForegroundColor Green

} else {
    Write-Host "  Already installed at $ComfyDir" -ForegroundColor Green
}

New-Item -ItemType Directory -Path "$ComfyDir\ComfyUI\models\checkpoints" -Force | Out-Null
New-Item -ItemType Directory -Path "$ComfyDir\ComfyUI\models\vae"         -Force | Out-Null
New-Item -ItemType Directory -Path "$ComfyDir\ComfyUI\output"             -Force | Out-Null

# ==========================================================================
# 3. STABLE DIFFUSION 1.5 MODEL
# ==========================================================================
Write-Host ""
Write-Host "[3/4] SD 1.5 model" -ForegroundColor Yellow

$ModelDir  = "$ComfyDir\ComfyUI\models\checkpoints"
$ModelFile = "$ModelDir\v1-5-pruned-emaonly.safetensors"

if (-not (Test-Path $ModelFile)) {
    Write-Host "  Attempting download from Hugging Face..." -ForegroundColor Gray
    Write-Host "  (If this fails, place any .safetensors manually in $ModelDir)" -ForegroundColor DarkGray

    $sdUrl = "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors"
    try {
        Invoke-WebRequest -Uri $sdUrl -OutFile $ModelFile -UseBasicParsing -Headers @{ "User-Agent" = "Mozilla/5.0" }
        Write-Host "  SD 1.5 downloaded." -ForegroundColor Green
    } catch {
        Write-Host "  Download failed. Manual step required:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "    Option A — Hugging Face" -ForegroundColor White
        Write-Host "      https://huggingface.co/runwayml/stable-diffusion-v1-5" -ForegroundColor DarkGray
        Write-Host "      Download: v1-5-pruned-emaonly.safetensors" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "    Option B — Civitai (any SD 1.5 model)" -ForegroundColor White
        Write-Host "      https://civitai.com/models/4384" -ForegroundColor DarkGray
        Write-Host "      Download any .safetensors and rename accordingly" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "    Place the file in: $ModelDir" -ForegroundColor Yellow
        Write-Host "    Then update ckpt_name in: $WorkflowDir\sd15-api.json" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Continuing setup. Image generation disabled until model is present." -ForegroundColor DarkGray
    }
} else {
    Write-Host "  Model already present." -ForegroundColor Green
}

# ==========================================================================
# 4. OPENCLAW CONFIG
# ==========================================================================
Write-Host ""
Write-Host "[4/4] OpenClaw configuration" -ForegroundColor Yellow

New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null

# .env
@"
# OpenClaw local backend -- Yggdrasil
# OLLAMA_API_KEY triggers auto-discovery of all local Ollama models.
OLLAMA_API_KEY=ollama-local
"@ | Set-Content -Path "$ConfigDir\.env" -Encoding UTF8
Write-Host "  $ConfigDir\.env" -ForegroundColor Gray

# openclaw.json
# workflowPath uses forward slashes (Windows accepts these in paths)
$WorkflowPath = "$WorkflowDir\sd15-api.json".Replace('\', '/')

@"
{
  "models": {
    "providers": {
      "ollama": {
        "apiKey": "ollama-local",
        "baseUrl": "http://127.0.0.1:11434"
      },
      "comfy": {
        "mode": "local",
        "baseUrl": "http://127.0.0.1:8188",
        "image": {
          "workflowPath": "$WorkflowPath",
          "promptNodeId": "6",
          "outputNodeId": "9"
        }
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "ollama/llama3.1:8b",
        "fallbacks": ["ollama/qwen2.5-coder:7b"]
      },
      "imageGenerationModel": {
        "primary": "comfy/workflow"
      },
      "memorySearch": {
        "provider": "ollama"
      }
    }
  }
}
"@ | Set-Content -Path "$ConfigDir\openclaw.json" -Encoding UTF8
Write-Host "  $ConfigDir\openclaw.json" -ForegroundColor Gray

# ==========================================================================
# DONE
# ==========================================================================
Write-Host ""
Write-Host "+==========================================+" -ForegroundColor Green
Write-Host "|  Setup complete.                         |" -ForegroundColor Green
Write-Host "+==========================================+" -ForegroundColor Green
Write-Host ""
Write-Host "Next:" -ForegroundColor Cyan
Write-Host "  1. Start services  ->  .\backend\start.ps1" -ForegroundColor White
Write-Host "  2. Launch OpenClaw ->  node openclaw.mjs" -ForegroundColor White
Write-Host ""
Write-Host "LLM models ready:" -ForegroundColor DarkGray
Write-Host "  ollama/llama3.1:8b       (primary)" -ForegroundColor DarkGray
Write-Host "  ollama/qwen2.5-coder:7b  (code fallback)" -ForegroundColor DarkGray
Write-Host "  ollama/nomic-embed-text  (memory embeddings)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Image gen: comfy/workflow -> SD 1.5 on RTX 3070 Ti" -ForegroundColor DarkGray
Write-Host ""
