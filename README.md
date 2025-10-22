# ComfyUI WanVideo 2.2 Docker for RunPod

Production-ready Docker image for running ComfyUI with WanVideo 2.2 support on RunPod.

## Features

- **GPU Optimized**: CUDA 12.8.1 + cuDNN on Ubuntu 24.04
- **PyTorch Nightly**: Latest features and performance improvements
- **WanVideo 2.2 Ready**: All required custom nodes pre-installed
- **Smart Startup**: Automatic network volume detection and symlink setup
- **Model Management**: Pre-downloads essential models, supports persistent storage
- **48GB VRAM Optimized**: bf16 precision, attention optimizations

## What's Included

### Custom Nodes (15+ installed)
- **ComfyUI-WanVideoWrapper** - Core WanVideo 2.2 support
- **ComfyUI-WanAnimatePreprocess** - Video preprocessing
- **ComfyUI-VideoHelperSuite** - Video I/O operations
- **comfyui_controlnet_aux** - Pose detection (DWPose, ViTPose)
- **ComfyUI-segment-anything-2** - SAM2 segmentation
- **ComfyUI-KJNodes** - Essential utility nodes
- **ComfyUI-Manager** - Node management
- **ComfyUI_IPAdapter_plus** - IP-Adapter support
- Plus 7 more utility and enhancement nodes

### Pre-downloaded Models (~2GB)
- CLIP Vision encoders (ViT-H, ViT-bigG)
- IP-Adapter models (SD1.5, SDXL)
- 4xLSDIR upscale model

### Python Packages
- PyTorch 2.7.0+ (nightly with CUDA 12.8)
- xformers, accelerate, transformers
- opencv-python, pillow, numpy, scipy
- sageattention (Linux optimization)
- triton (where supported)
- JupyterLab (optional debugging)

## Building the Image

### Prerequisites
- Docker with BuildKit support
- NVIDIA Container Toolkit (for GPU support)
- At least 20GB free disk space

### Build Command

```bash
# Standard build
docker build -t comfyui-wanvideo:latest .

# Build with BuildKit caching (faster rebuilds)
DOCKER_BUILDKIT=1 docker build -t comfyui-wanvideo:latest .
```

### Build Time
- First build: 30-60 minutes (downloads ~10GB)
- Subsequent builds: 5-10 minutes (with cache)

## Running Locally (Testing)

### Quick Start
```bash
docker run --gpus all -p 8188:8188 comfyui-wanvideo:latest
```

### With Network Volume (RunPod simulation)
```bash
docker run --gpus all \
  -p 8188:8188 \
  -v /path/to/models:/runpod-volume \
  comfyui-wanvideo:latest
```

### With JupyterLab
```bash
docker run --gpus all \
  -p 8188:8188 \
  -p 8888:8888 \
  -e ENABLE_JUPYTER=true \
  comfyui-wanvideo:latest
```

## Deploying to RunPod

### Step 1: Push to GitHub Container Registry (GHCR)

We'll use GHCR because it offers:
- ✅ No rate limits (unlimited pulls)
- ✅ Free unlimited private repositories
- ✅ Integrated with GitHub workflow
- ✅ Works perfectly with RunPod

#### First-time Setup

1. **Create a GitHub Personal Access Token** (one-time setup):
   - Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Click "Generate new token (classic)"
   - Give it a name: "GHCR Docker Push"
   - Select scopes:
     - ✅ `write:packages` (upload packages)
     - ✅ `read:packages` (download packages)
     - ✅ `delete:packages` (optional - delete old versions)
   - Click "Generate token"
   - **Copy the token** (you won't see it again!)

2. **Login to GHCR** (replace `YOUR_USERNAME` and paste your token):
   ```bash
   echo YOUR_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin
   ```

   You should see: `Login Succeeded`

#### Build, Tag, and Push

**Option A: Use the automated script (recommended)**

```bash
# Make the script executable (first time only)
chmod +x build-and-push.sh

# Run the script
./build-and-push.sh
```

The script will:
- Prompt for your GitHub username
- Help you login to GHCR if needed
- Build the Docker image with caching
- Tag it properly for GHCR
- Push to your registry
- Show next steps

**Option B: Manual commands**

```bash
# Build the image
docker build -t comfyui-wanvideo:latest .

# Tag for GHCR (replace YOUR_USERNAME with your GitHub username)
docker tag comfyui-wanvideo:latest ghcr.io/YOUR_USERNAME/comfyui-wanvideo:latest

# Push to GHCR
docker push ghcr.io/YOUR_USERNAME/comfyui-wanvideo:latest
```

**Option C: Automated with GitHub Actions**

Simply push to your GitHub repository and the workflow will automatically:
- Build the Docker image on every push to main/master
- Push to GHCR with proper tags
- Handle caching for faster builds

See `.github/workflows/docker-build.yml` for configuration.

#### Make the Image Public (Required for RunPod)

After pushing, make your package public:
1. Go to your GitHub profile → Packages
2. Click on `comfyui-wanvideo`
3. Click "Package settings" (bottom right)
4. Scroll to "Danger Zone"
5. Click "Change visibility" → Make Public
6. Type the package name to confirm

**Note**: RunPod can use private images, but public is simpler (no authentication needed).

### Step 2: Create RunPod Template

1. Go to RunPod.io → Templates → New Template
2. Fill in the details:
   - **Template Name**: ComfyUI WanVideo 2.2
   - **Container Image**: `ghcr.io/YOUR_USERNAME/comfyui-wanvideo:latest`
   - **Container Disk**: 20 GB
   - **Expose HTTP Ports**: `8188` (ComfyUI), `8888` (JupyterLab - optional)
   - **Expose TCP Ports**: Leave empty

3. Environment Variables (optional):
   - `ENABLE_JUPYTER=true` - Enable JupyterLab

4. Docker Command: Leave empty (uses CMD from Dockerfile)

### Step 3: Deploy Pod

1. Go to Pods → Deploy
2. Select your template
3. Choose GPU (48GB VRAM recommended):
   - RTX A6000 (48GB)
   - A100 40GB/80GB
   - RTX 6000 Ada (48GB)

4. **Important**: Attach a Network Volume
   - Create new volume or use existing
   - Mount path: `/runpod-volume`
   - Size: 100GB+ (for models)

5. Start the pod

### Step 4: Access ComfyUI

1. Wait for pod to start (30-60 seconds)
2. Click "Connect" → "HTTP Service [8188]"
3. ComfyUI interface should load

## Network Volume Structure

The startup script automatically creates this structure on your RunPod network volume:

```
/runpod-volume/
├── models/
│   ├── diffusion_models/     ← Put WanVideo models here
│   ├── text_encoders/         ← T5 encoders
│   ├── vae/                   ← VAE models
│   ├── clip_vision/           ← Pre-populated from image
│   ├── loras/                 ← LoRA models
│   ├── controlnet/            ← ControlNet models
│   ├── sam2/                  ← SAM2 checkpoints
│   ├── upscale_models/        ← Pre-populated with 4xLSDIR
│   └── ipadapter/             ← Pre-populated IP-Adapters
├── input/                     ← Upload input images/videos here
├── output/                    ← Generated outputs saved here
└── workflows/                 ← Save your workflows here
```

## Required Models (Upload to Network Volume)

### WanVideo 2.2 Models (~50GB)
Upload these to `/runpod-volume/models/diffusion_models/`:
- `wanvideo_v2_2.safetensors` - Main model

### Text Encoders (~20GB)
Upload to `/runpod-volume/models/text_encoders/`:
- `t5-v1_1-xxl-encoder-bf16.safetensors`
- `clip-vit-large-patch14.safetensors`

### VAE (~400MB)
Upload to `/runpod-volume/models/vae/`:
- `wanvideo_vae.safetensors`

### Optional: SAM2 for Segmentation (~3GB)
Upload to `/runpod-volume/models/sam2/`:
- `sam2_hiera_large.pt`

## Performance Optimization

### For 48GB VRAM GPUs
The startup script automatically enables:
- `--bf16-vae` - Use bfloat16 for VAE (saves VRAM)
- `--use-split-cross-attention` - Split attention for efficiency
- `--preview-method auto` - Efficient preview generation

### SageAttention
SageAttention is installed but requires Linux. It provides 2x attention speedup when available.

### Memory Management
For 1920x1080 videos at 81 frames:
- Expected VRAM: 35-45GB
- Leaves ~3GB buffer for system

## Troubleshooting

### Pod won't start
- Check GHCR image is public (see "Make the Image Public" section)
- Verify GPU is available in RunPod region
- Check RunPod logs for errors
- Ensure image name is correct: `ghcr.io/YOUR_USERNAME/comfyui-wanvideo:latest`

### ComfyUI shows errors on startup
- Wait 60 seconds for full initialization
- Check network volume is mounted at `/runpod-volume`
- Verify models are in correct directories

### Out of memory errors
- Reduce video resolution or frame count
- Enable `--lowvram` mode (add to start.sh)
- Use smaller batch sizes in workflows

### Models not loading
- Check models are in correct subdirectories
- Verify symlinks: `ls -la /workspace/ComfyUI/models`
- Models should be in `/runpod-volume/models/`

### Custom nodes failing
- Check ComfyUI logs in pod terminal
- Some nodes may need additional models
- Use ComfyUI-Manager to reinstall failed nodes

## Updating the Image

### Option 1: Use the script (easiest)
```bash
./build-and-push.sh
# Choose option 2 for full rebuild when prompted
```

### Option 2: Manual rebuild
```bash
# Rebuild from scratch
docker build --no-cache -t comfyui-wanvideo:latest .

# Tag for GHCR
docker tag comfyui-wanvideo:latest ghcr.io/YOUR_USERNAME/comfyui-wanvideo:latest

# Push to GHCR
docker push ghcr.io/YOUR_USERNAME/comfyui-wanvideo:latest
```

### Option 3: GitHub Actions (automatic)
Simply push your changes to GitHub:
```bash
git add .
git commit -m "Update Docker configuration"
git push
```
The GitHub Actions workflow will automatically build and push the new image.

### Update RunPod pod
1. Terminate existing pod
2. Deploy new pod with same template (pulls latest image)
3. Reattach same network volume (keeps models)

## File Structure

```
.
├── .github/
│   └── workflows/
│       └── docker-build.yml  # GitHub Actions workflow for auto-build
├── Dockerfile                # Main build instructions
├── start.sh                  # Startup script for ComfyUI
├── build-and-push.sh         # Helper script to build and push to GHCR
├── .dockerignore             # Build exclusions
└── README.md                 # This file
```

## Technical Specifications

- **Base Image**: nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04
- **Python**: 3.12 in virtual environment
- **PyTorch**: 2.7.0+ nightly (cu128)
- **ComfyUI**: Latest from official repo
- **Image Size**: ~12-15GB (uncompressed)
- **Startup Time**: 30-60 seconds
- **Ports**: 8188 (ComfyUI), 8888 (JupyterLab)

## Security Notes

- Runs as root (standard for RunPod)
- No authentication on ComfyUI (use RunPod's network security)
- JupyterLab has no password (only enable in trusted networks)

## License

This Dockerfile and associated scripts are provided as-is for use with ComfyUI and RunPod.

## Support

For issues:
1. Check RunPod pod logs
2. Verify GPU and network volume setup
3. Review ComfyUI console output
4. Check custom node documentation

## Next Steps

1. Build the image: `docker build -t comfyui-wanvideo:latest .`
2. Test locally: `docker run --gpus all -p 8188:8188 comfyui-wanvideo:latest`
3. Push to registry
4. Create RunPod template
5. Deploy pod with network volume
6. Upload WanVideo models
7. Start generating!
