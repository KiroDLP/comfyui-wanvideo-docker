# RunPod Template Configuration

Complete copy-paste guide for deploying on RunPod.

---

## Basic Settings

### **Template Name**
```
ComfyUI WanVideo 2.2
```

### **Container Image**
```
ghcr.io/kirodlp/comfyui-wanvideo-docker:latest
```

### **Container Disk**
```
20
```
(GB - for the Docker image itself)

---

## Port Configuration

### **HTTP Ports**

Add two ports:

**Port 1:**
- Label: `ComfyUI`
- Port Number: `8188`

**Port 2:**
- Label: `JupyterLab`
- Port Number: `8888`

### **TCP Ports**
Leave empty

---

## Environment Variables

Copy and paste ALL of these:

```
download_480p_native_models=false
download_720p_native_models=false
download_wan_fun_and_sdxl_helper=false
download_vace=false
civitai_token=
LORAS_IDS_TO_DOWNLOAD=
CHECKPOINT_IDS_TO_DOWNLOAD=
ENABLE_JUPYTER=true
```

### Variable Explanations:

| Variable | Description | Default |
|----------|-------------|---------|
| `download_480p_native_models` | Download Wan 1.3B and 14B T2V/I2V 480p models (~20GB) | `false` |
| `download_720p_native_models` | Download Wan 1.3B and 14B T2V/I2V 720p models (~30GB) | `false` |
| `download_wan_fun_and_sdxl_helper` | Download Wan Fun 1.3B/14B + SDXL ControlNet (~15GB) | `false` |
| `download_vace` | Download Wan VACE model (~10GB) | `false` |
| `civitai_token` | Your CivitAI API token (optional, for auto-downloading LoRAs) | (empty) |
| `LORAS_IDS_TO_DOWNLOAD` | Comma-separated CivitAI LoRA version IDs (e.g., `123456,789012`) | (empty) |
| `CHECKPOINT_IDS_TO_DOWNLOAD` | Comma-separated CivitAI checkpoint version IDs | (empty) |
| `ENABLE_JUPYTER` | Enable JupyterLab access on port 8888 | `true` |

### Example Configuration for 720p Video Generation:

```
download_480p_native_models=false
download_720p_native_models=true
download_wan_fun_and_sdxl_helper=false
download_vace=false
civitai_token=
LORAS_IDS_TO_DOWNLOAD=
CHECKPOINT_IDS_TO_DOWNLOAD=
ENABLE_JUPYTER=true
```

---

## Additional Configuration

### **Registry Auth**
Leave empty (if your image is public on GHCR)

### **Start Command**
Leave empty (uses `/start.sh` from Docker)

### **Docker Command Override**
Leave empty

---

## Deployment Instructions

### Step 1: GPU Selection
⚠️ **IMPORTANT**: Select CUDA 12.8 compatible GPUs

In the GPU filter:
- Click "Additional Filters"
- Under "CUDA Version", select **12.8**

Recommended GPUs (48GB VRAM):
- RTX A6000 (48GB)
- RTX 6000 Ada (48GB)
- A100 40GB/80GB

### Step 2: Network Volume
⚠️ **REQUIRED**: Attach a network volume for model persistence

- **Mount Path**: `/runpod-volume`
- **Size**: 100GB+ (models are large!)

Without a network volume, models download every time you start a new pod.

### Step 3: Deploy
1. Configure environment variables (set which models to download)
2. Click **Deploy**
3. First deployment takes **5-20 minutes** depending on models selected
4. Future deployments with same network volume are instant!

---

## Accessing ComfyUI

1. Wait for pod to start
2. Click **Connect**
3. Click **HTTP Service [8188]**
4. ComfyUI interface opens

---

## Accessing JupyterLab

1. Click **Connect**
2. Click **HTTP Service [8888]**
3. JupyterLab opens (no password required)

---

## Model Download Sizes

Estimate your network volume size:

| Models | Approximate Size |
|--------|-----------------|
| 480p native models | ~20GB |
| 720p native models | ~30GB |
| Wan Fun + SDXL | ~15GB |
| VACE | ~10GB |
| Pre-installed (CLIP, IP-Adapter, etc.) | ~2GB |

**Recommended Network Volume**: 100GB minimum

---

## Getting Your CivitAI Token

1. Go to https://civitai.com
2. Sign in or create account
3. Click your profile → Settings
4. Click "API Keys"
5. Click "Add API Key"
6. Copy the token
7. Paste into `civitai_token` environment variable

---

## Finding CivitAI Model IDs

1. Go to the model page on CivitAI
2. Click the version you want
3. Look at the URL: `https://civitai.com/models/12345?modelVersionId=67890`
4. The **modelVersionId** (67890) is what you need
5. Add to `LORAS_IDS_TO_DOWNLOAD` or `CHECKPOINT_IDS_TO_DOWNLOAD`

Example for multiple IDs:
```
LORAS_IDS_TO_DOWNLOAD=67890,12345,99999
```

---

## Troubleshooting

### Pod won't start
- Check that image is public on GHCR
- Verify GPU has CUDA 12.8 support
- Check RunPod logs for errors

### Models not downloading
- Check environment variables are set to `true` (not `True` or `1`)
- Ensure network volume is mounted at `/runpod-volume`
- Check pod logs for download errors

### Out of space errors
- Increase network volume size
- Don't download all models at once
- 720p models are large (~30GB)

### ComfyUI shows "missing custom nodes"
- Open ComfyUI Manager
- Click "Install missing custom nodes"
- Click "Try fix"
- Restart pod if needed

---

## Cost Optimization

### Strategy 1: Download Once, Use Forever
1. Deploy pod with network volume
2. Set environment variables to download models
3. Wait for download (20 minutes)
4. Terminate pod
5. Future deployments: Models already on volume = instant start!

### Strategy 2: Selective Downloads
Only download the models you need:
- For 720p videos: Only set `download_720p_native_models=true`
- For experiments: Start with 480p models (smaller/faster)

### Strategy 3: Use Spot Instances
- RunPod spot instances are 70% cheaper
- Safe for rendering (can resume if interrupted)

---

## Complete Template Summary

```yaml
Template Name: ComfyUI WanVideo 2.2
Container Image: ghcr.io/kirodlp/comfyui-wanvideo-docker:latest
Container Disk: 20 GB

HTTP Ports:
  - Label: ComfyUI, Port: 8188
  - Label: JupyterLab, Port: 8888

Environment Variables:
  download_480p_native_models: false
  download_720p_native_models: false
  download_wan_fun_and_sdxl_helper: false
  download_vace: false
  civitai_token: (your token)
  LORAS_IDS_TO_DOWNLOAD: (comma-separated IDs)
  CHECKPOINT_IDS_TO_DOWNLOAD: (comma-separated IDs)
  ENABLE_JUPYTER: true

Network Volume:
  Mount: /runpod-volume
  Size: 100+ GB

GPU Filter: CUDA 12.8
```

---

## Next Steps After Deployment

1. Access ComfyUI at port 8188
2. Load a WanVideo workflow
3. Generate your first video!
4. Check `/workspace/ComfyUI/output/` for results

Happy generating! 🎬
