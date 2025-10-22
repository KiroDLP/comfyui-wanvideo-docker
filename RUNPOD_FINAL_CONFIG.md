# 🚀 RUNPOD TEMPLATE - FINAL CONFIGURATION

## Copy-Paste This Entire Configuration Into RunPod

---

## ⚙️ BASIC SETTINGS

### Template Name
```
ComfyUI WanVideo 2.2 Complete
```

### Container Image
```
ghcr.io/kirodlp/comfyui-wanvideo-docker:latest
```

### Container Disk
```
20
```

---

## 🌐 HTTP PORTS

**Add these two ports exactly:**

| Port Label | Port Number |
|------------|-------------|
| `ComfyUI` | `8188` |
| `JupyterLab` | `8888` |

---

## 🔌 TCP PORTS
```
Leave Empty
```

---

## 🔐 REGISTRY AUTH
```
Leave Empty
(if your GHCR image is public)
```

---

## 🎯 START COMMAND
```
Leave Empty
(uses /start.sh from Docker)
```

---

## 📋 DOCKER COMMAND
```
Leave Empty
```

---

## 🌍 ENVIRONMENT VARIABLES

**COPY ALL OF THESE EXACTLY:**

```
download_wanvideo_22_complete=false
download_wananimate=false
download_480p_native_models=false
download_720p_native_models=false
download_wan_fun_and_sdxl_helper=false
download_vace=false
civitai_token=
LORAS_IDS_TO_DOWNLOAD=
CHECKPOINT_IDS_TO_DOWNLOAD=
ENABLE_JUPYTER=true
```

---

## 📖 ENVIRONMENT VARIABLES EXPLAINED

| Variable | What It Downloads | Size | Use Case |
|----------|------------------|------|----------|
| `download_wanvideo_22_complete` | **WanVideo 2.2 FULL**: Transformer + T5 encoder + CLIP encoder + VAE | ~50GB | **MAIN MODEL - Start here!** |
| `download_wananimate` | WanAnimate transformer model | ~25GB | Animation-focused generation |
| `download_480p_native_models` | Wan 1.3B + 14B T2V/I2V 480p | ~20GB | Lower resolution, faster |
| `download_720p_native_models` | Wan 1.3B + 14B T2V/I2V 720p | ~30GB | Higher resolution |
| `download_wan_fun_and_sdxl_helper` | Wan Fun 1.3B/14B + SDXL ControlNet | ~15GB | Fun/creative workflows |
| `download_vace` | Wan VACE model | ~10GB | Video editing/enhancement |
| `civitai_token` | Your CivitAI API token | - | For auto-downloading LoRAs |
| `LORAS_IDS_TO_DOWNLOAD` | Comma-separated CivitAI LoRA IDs | Varies | Custom LoRAs |
| `CHECKPOINT_IDS_TO_DOWNLOAD` | Comma-separated checkpoint IDs | Varies | Custom checkpoints |
| `ENABLE_JUPYTER` | Enable JupyterLab on port 8888 | - | For debugging |

---

## 🎬 RECOMMENDED STARTER CONFIGURATION

**For WanVideo 2.2 (1920x1080 video generation):**

```
download_wanvideo_22_complete=true
download_wananimate=false
download_480p_native_models=false
download_720p_native_models=false
download_wan_fun_and_sdxl_helper=false
download_vace=false
civitai_token=
LORAS_IDS_TO_DOWNLOAD=
CHECKPOINT_IDS_TO_DOWNLOAD=
ENABLE_JUPYTER=true
```

**This downloads everything you need for WanVideo 2.2!**

---

## 💾 NETWORK VOLUME CONFIGURATION

### ⚠️ REQUIRED - Network Volume Settings

| Setting | Value |
|---------|-------|
| **Mount Path** | `/runpod-volume` |
| **Recommended Size** | `150GB` minimum |
| **For full setup** | `250GB` recommended |

**Why you need this:**
- Models persist between pod deployments
- First deployment downloads models (10-30 mins)
- Subsequent deployments = instant startup!

---

## 🖥️ GPU CONFIGURATION

### ⚠️ IMPORTANT - Select CUDA 12.8

**Before deploying:**
1. Click "Additional Filters"
2. Under "CUDA Version", select: **12.8**

### Recommended GPUs (48GB VRAM for 1920x1080):

| GPU | VRAM | Best For |
|-----|------|----------|
| RTX A6000 | 48GB | ✅ Perfect for 1080p |
| RTX 6000 Ada | 48GB | ✅ Perfect for 1080p |
| A100 80GB | 80GB | ✅ Perfect, can do 4K |
| A100 40GB | 40GB | ⚠️ Works for 1080p |
| RTX 4090 | 24GB | ⚠️ 480p/720p only |

---

## 📦 DEPLOYMENT STEPS

### Step 1: Create the Template
1. Go to RunPod → Templates → New Template
2. Copy-paste all settings from this document
3. Click "Save Template"

### Step 2: Deploy Your First Pod
1. Go to Pods → Deploy
2. Select your template
3. **Select CUDA 12.8 in filters**
4. **Attach network volume** (150GB+)
5. Choose GPU (RTX A6000 recommended)
6. Click "Deploy"

### Step 3: Wait for Setup
- First deployment: **10-30 minutes** (downloading ~50GB)
- Watch progress in pod logs
- Future deployments: **30 seconds** (models already on volume!)

### Step 4: Access ComfyUI
1. Wait for "Starting ComfyUI on port 8188..." in logs
2. Click "Connect"
3. Click "HTTP Service [8188]"
4. ComfyUI opens in browser!

---

## 🔍 ACCESSING SERVICES

### ComfyUI Web Interface
```
Click: Connect → HTTP Service [8188]
URL: https://your-pod-id-8188.proxy.runpod.net
```

### JupyterLab (if enabled)
```
Click: Connect → HTTP Service [8888]
URL: https://your-pod-id-8888.proxy.runpod.net
No password required!
```

---

## 📂 FILE LOCATIONS INSIDE POD

```
/workspace/ComfyUI/           # ComfyUI installation
/workspace/ComfyUI/models/    # Symlink to /runpod-volume/models/
/workspace/ComfyUI/input/     # Symlink to /runpod-volume/input/
/workspace/ComfyUI/output/    # Symlink to /runpod-volume/output/

/runpod-volume/models/diffusion_models/    # WanVideo models
/runpod-volume/models/text_encoders/       # T5, CLIP encoders
/runpod-volume/models/vae/                 # VAE models
/runpod-volume/models/loras/               # LoRAs
/runpod-volume/models/controlnet/          # ControlNet models
/runpod-volume/input/                      # Upload images/videos here
/runpod-volume/output/                     # Generated outputs
```

---

## 🎨 GETTING YOUR CIVITAI TOKEN (Optional)

1. Go to https://civitai.com
2. Sign in/create account
3. Profile → Settings → API Keys
4. Click "Add API Key"
5. Copy the token
6. Paste into `civitai_token` environment variable

---

## 🔢 FINDING CIVITAI MODEL VERSION IDS

1. Go to model page on CivitAI
2. Select the version you want
3. Look at URL: `https://civitai.com/models/12345?modelVersionId=67890`
4. The `modelVersionId=67890` is what you need
5. Add to `LORAS_IDS_TO_DOWNLOAD` or `CHECKPOINT_IDS_TO_DOWNLOAD`

**Example for multiple models:**
```
LORAS_IDS_TO_DOWNLOAD=67890,12345,99999
CHECKPOINT_IDS_TO_DOWNLOAD=11111,22222
```

---

## 💰 COST ESTIMATION

### First Deployment (with downloads):
- A6000 48GB: ~$0.79/hr
- Download time: ~20-30 mins
- Cost: **~$0.40**

### Subsequent Deployments:
- Startup: **30 seconds** (instant!)
- Generate 5sec 1080p video: ~2 minutes
- Cost per video: **~$0.03**

### Using Network Volume:
- 150GB storage: **~$3/month**
- **Worth it!** - Models persist forever

---

## 🐛 TROUBLESHOOTING

### Pod Won't Start
- ✅ Check image is public on GHCR
- ✅ Verify CUDA 12.8 selected
- ✅ Check RunPod logs for errors

### Models Not Downloading
- ✅ Check env vars set to `true` (lowercase)
- ✅ Verify network volume mounted at `/runpod-volume`
- ✅ Check pod logs for download progress

### Out of Memory
- ✅ Use 48GB+ VRAM GPU for 1080p
- ✅ Reduce video resolution to 720p/480p
- ✅ Reduce frame count

### "Missing Custom Nodes" Error
- ✅ Open ComfyUI Manager
- ✅ Click "Install missing custom nodes"
- ✅ Click "Try fix"
- ✅ Restart pod if needed

---

## 📊 WHAT GETS DOWNLOADED

### With `download_wanvideo_22_complete=true`:

```
✅ wanvideo_v2_2.safetensors           (~25GB) - Main transformer
✅ t5-v1_1-xxl-encoder-bf16.safetensors (~20GB) - Text encoder
✅ clip-vit-large-patch14.safetensors   (~1GB)  - Text encoder
✅ wanvideo_vae.safetensors             (~400MB)- VAE decoder

Total: ~50GB
```

**This is everything you need to generate 1920x1080 videos with WanVideo 2.2!**

---

## ✅ QUICK START CHECKLIST

- [ ] Build Docker locally and push to GHCR
- [ ] Make GHCR image public
- [ ] Create RunPod template with config above
- [ ] Set `download_wanvideo_22_complete=true`
- [ ] Select CUDA 12.8 GPU filter
- [ ] Attach 150GB+ network volume to `/runpod-volume`
- [ ] Deploy pod
- [ ] Wait 20-30 mins for model download
- [ ] Access ComfyUI on port 8188
- [ ] Generate your first video! 🎬

---

## 🎉 YOU'RE READY!

Everything is configured. Just build the Docker, push to GHCR, and deploy on RunPod with these exact settings!

**Repository:** https://github.com/KiroDLP/comfyui-wanvideo-docker
**Docker Image:** ghcr.io/kirodlp/comfyui-wanvideo-docker:latest

Happy generating! 🚀
