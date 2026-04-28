# Stable Diffusion (Local — ComfyUI)

Generate images locally via ComfyUI running on Yggdrasil.
No API keys. No cloud. Runs entirely on the RTX 3070 Ti.

## Provider

| Property | Value |
|----------|-------|
| Provider | `comfy` |
| Model ref | `comfy/workflow` |
| ComfyUI URL | `http://127.0.0.1:8188` |
| Backend | SD 1.5 via DPM++ 2M Karras |

## How to use

Just ask for an image:

```
Generate an image of a dark forest at night, cinematic lighting
```

Or call the tool directly:

```
/tool image_generate prompt="cyberpunk city skyline at dusk, neon lights, rain"
```

OpenClaw routes the prompt to ComfyUI's SD 1.5 workflow and returns the result.

## Workflow: sd15-api.json

File: `backend/workflows/sd15-api.json`

| Node | Type | Role |
|------|------|------|
| 4 | CheckpointLoaderSimple | Loads SD 1.5 model |
| 5 | EmptyLatentImage | 512×512 canvas |
| **6** | CLIPTextEncode | **Positive prompt** — `promptNodeId` |
| 7 | CLIPTextEncode | Negative prompt |
| 3 | KSampler | DPM++ 2M Karras, 20 steps, CFG 7.0 |
| 8 | VAEDecode | Decode latents to image |
| **9** | SaveImage | **Output** — `outputNodeId` |

## Services required

Both must be running before image generation will work:

| Service | Port | Command |
|---------|------|---------|
| ComfyUI | 8188 | `.\backend\start.ps1` |
| Ollama  | 11434 | `.\backend\start.ps1` |

Check status: `.\backend\status.ps1`

## Model

Default: `v1-5-pruned-emaonly.safetensors` (Stable Diffusion 1.5)

Location:
```
backend\comfyui\ComfyUI\models\checkpoints\
```

To swap models:
1. Drop any `.safetensors` file into that directory
2. Edit node 4 `ckpt_name` in `backend/workflows/sd15-api.json`
3. Restart ComfyUI

SDXL works on 8GB VRAM with the default settings — just use a 1024×1024 resolution.
Update node 5 `width`/`height` in the workflow JSON accordingly.

## Troubleshooting

**No output / silent failure**
- Run `.\backend\status.ps1` — check ComfyUI is `[RUNNING]`
- Check ComfyUI window for error output

**Missing model error in ComfyUI**
- Confirm `.safetensors` file exists in `checkpoints\` folder
- Filename in node 4 must exactly match the file on disk

**Port 8188 already in use**
```powershell
Get-NetTCPConnection -LocalPort 8188 | Select-Object OwningProcess
```
