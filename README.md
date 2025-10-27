# ComfyUI WanVideo 2.2 Animate Docker for RunPod

**Production-ready Docker image for running ComfyUI with WanVideo 2.2 Animate support on RunPod.**

## V3 Updates (Latest - STABLE)

- **✅ WanVideoWrapper FIXED**: Resolved import failures with proper dependency installation
- **PyTorch Nightly 2.10+cu128**: Required for WanVideo 2.2 Animate compatibility
- **CUDA 12.8.1 + cuDNN**: Optimized for RTX 4090/5090, H100, and newer GPUs (driver >= 560)
- **Verified Working Configuration**: Based on successful production deployment
- **Simplified Model Downloads**: Direct URLs, no complex env variable logic
- **Critical Fix Documented**: Complete troubleshooting guide included

### Key Differences from V2

| Aspect | V2 (Broken) | V3 (Working) |
|--------|-------------|--------------|
| PyTorch | 2.7.0 stable | 2.10.0.dev nightly (cu128) |
| WanVideoWrapper Requirements | ❌ Skipped | ✅ Installed after PyTorch |
| Model Downloads | Complex env vars | Simple direct downloads |
| Import Success | ❌ Failed | ✅ Working |
| diffusers Version | Pinned 0.33.0 | Latest 0.35.2 (GGUF support) |

## 🚨 Critical Fix: WanVideoWrapper Requirements Installation

**THE ROOT CAUSE OF ALL IMPORT FAILURES**

The V2 build was completely skipping WanVideoWrapper's `requirements.txt` installation, causing missing dependencies:
- `peft>=0.17.0` - Parameter-efficient fine-tuning
- `sentencepiece>=0.2.0` - Text tokenization
- `pyloudnorm` - Audio processing
- And other critical packages

**The Fix** (Dockerfile:104-105):
```dockerfile
# V3 FIX: Install WanVideoWrapper requirements AFTER PyTorch nightly
# The requirements.txt does NOT pin torch versions - only requires torch>=2.0.0 via accelerate
# Since PyTorch nightly 2.10+ is already installed, pip won't downgrade
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r /workspace/ComfyUI/custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt
```

**Why This Works**:
1. PyTorch nightly (2.10+) is installed FIRST (Dockerfile:40-43)
2. WanVideoWrapper requirements.txt has NO torch version pins
3. It only requires `torch>=2.0.0` indirectly through `accelerate>=1.2.1`
4. pip sees nightly satisfies the requirement, so NO DOWNGRADE occurs
5. All missing dependencies (peft, sentencepiece, etc.) are installed
6. WanVideoWrapper imports successfully ✅

## Features

- **GPU Optimized**: CUDA 12.8.1 + cuDNN on Ubuntu 24.04
- **PyTorch Nightly**: 2.10.0.dev+cu128 with Blackwell/Hopper support
- **WanVideo 2.2 Animate Ready**: All dependencies correctly installed
- **Smart Startup**: Automatic model downloads with correct URLs
- **Verified Working**: Based on successful production deployment logs
- **Complete Documentation**: Every problem and fix documented below

## What's Included

### Custom Nodes (15+ installed)
- **ComfyUI-WanVideoWrapper** - Core WanVideo 2.2 support (NOW WORKS!)
- **ComfyUI-WanAnimatePreprocess** - Video preprocessing
- **ComfyUI-VideoHelperSuite** - Video I/O operations
- **comfyui_controlnet_aux** - Pose detection (DWPose, ViTPose)
- **ComfyUI-segment-anything-2** - SAM2 segmentation
- **ComfyUI-KJNodes** - Essential utility nodes
- **ComfyUI-Manager** - Node management
- **ComfyUI_IPAdapter_plus** - IP-Adapter support
- Plus 7 more utility and enhancement nodes

### Runtime Model Downloads (V3 - Verified Working)

All models download automatically on first run to `/workspace/ComfyUI/models/`:

#### Detection Models (for WanAnimate preprocessing)
- `vitpose-l-wholebody.onnx` (~1.15GB)
- `yolov10m.onnx` (~59MB)

#### Diffusion Models (Main models)
- `Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors` (~17GB)
- `wan2.1_t2v_14B_fp8_scaled.safetensors` (alternative model)

#### LoRAs (Enhancement models)
- `WanAnimate_relight_lora_fp16.safetensors` (~1.34GB)
- `lightx2v_I2V_14B_480p_cfg_step_distill_rank256_bf16.safetensors` (~2.72GB)
- `lightx2v_T2V_14B_cfg_step_distill_v2_lora_rank64_bf16.safetensors`
- `wan_alpha_2.1_rgba_lora.safetensors`

#### Text Encoders
- `umt5-xxl-enc-bf16.safetensors`
- `umt5_xxl_fp8_e4m3fn_scaled.safetensors`

#### VAE Models
- `Wan2_1_VAE_bf16.safetensors`
- `wan_alpha_2.1_vae_rgb_channel.safetensors`
- `wan_alpha_2.1_vae_alpha_channel.safetensors`

#### CLIP Vision
- `clip_vision_h.safetensors`

**Total Downloads**: ~25-30GB (all models included)

### Python Packages (V3)
- **PyTorch**: 2.10.0.dev20250924+cu128 (nightly)
- **diffusers**: 0.35.2 (with GGUF quantization support)
- **accelerate, transformers, peft, sentencepiece** (WanVideoWrapper deps)
- **opencv-python, pillow, numpy, scipy**
- **triton** (where supported)
- **JupyterLab** (optional debugging)

## Building the Image

### Prerequisites
- Docker with BuildKit support
- NVIDIA Container Toolkit (for GPU support)
- At least 30GB free disk space

### Build Command (V3)

```bash
# V3 build (latest stable)
docker build -t ghcr.io/YOUR_USERNAME/comfyui-wanvideo-docker:v3 .

# Tag for GHCR
docker tag ghcr.io/YOUR_USERNAME/comfyui-wanvideo-docker:v3 ghcr.io/YOUR_USERNAME/comfyui-wanvideo-docker:latest

# Build with BuildKit caching (faster rebuilds)
DOCKER_BUILDKIT=1 docker build -t ghcr.io/YOUR_USERNAME/comfyui-wanvideo-docker:v3 .

# Push to GHCR
docker push ghcr.io/YOUR_USERNAME/comfyui-wanvideo-docker:v3
docker push ghcr.io/YOUR_USERNAME/comfyui-wanvideo-docker:latest
```

### Build Time (V3)
- First build: 25-35 minutes (downloads ~4-5GB)
- Subsequent builds: 5-10 minutes (with cache)
- **Image size: ~8GB** (includes all dependencies)

## Running Locally (Testing)

### Quick Start (V3)
```bash
# Basic run with automatic model downloads
docker run --gpus all -p 8188:8188 \
  -v /path/to/models:/workspace/ComfyUI/models \
  ghcr.io/YOUR_USERNAME/comfyui-wanvideo-docker:v3
```

### With JupyterLab (V3)
```bash
docker run --gpus all \
  -p 8188:8188 \
  -p 8888:8888 \
  -v /path/to/models:/workspace/ComfyUI/models \
  -e ENABLE_JUPYTER=true \
  ghcr.io/YOUR_USERNAME/comfyui-wanvideo-docker:v3
```

### Selective Model Downloads (V3)

**Download only core models (minimal setup)**:
```bash
docker run --gpus all -p 8188:8188 \
  -v /path/to/models:/workspace/ComfyUI/models \
  -e DOWNLOAD_WANVIDEO_COMPLETE=false \
  -e DOWNLOAD_DIFFUSION_MODELS=true \
  -e DOWNLOAD_TEXT_ENCODERS=true \
  -e DOWNLOAD_VAE=true \
  ghcr.io/YOUR_USERNAME/comfyui-wanvideo-docker:v3
```

**Skip LoRAs and detection models**:
```bash
docker run --gpus all -p 8188:8188 \
  -v /path/to/models:/workspace/ComfyUI/models \
  -e DOWNLOAD_LORAS=false \
  -e DOWNLOAD_DETECTION_MODELS=false \
  ghcr.io/YOUR_USERNAME/comfyui-wanvideo-docker:v3
```

**Download everything (default behavior)**:
```bash
docker run --gpus all -p 8188:8188 \
  -v /path/to/models:/workspace/ComfyUI/models \
  -e DOWNLOAD_WANVIDEO_COMPLETE=true \
  ghcr.io/YOUR_USERNAME/comfyui-wanvideo-docker:v3
```

## Deploying to RunPod

### Step 1: Push to GitHub Container Registry (GHCR)

#### First-time Setup

1. **Create a GitHub Personal Access Token** (one-time setup):
   - Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Click "Generate new token (classic)"
   - Give it a name: "GHCR Docker Push"
   - Select scopes:
     - ✅ `write:packages` (upload packages)
     - ✅ `read:packages` (download packages)
   - Click "Generate token"
   - **Copy the token** (you won't see it again!)

2. **Login to GHCR**:
   ```bash
   echo YOUR_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin
   ```

#### Build and Push

```bash
# Build the V3 image
docker build -t ghcr.io/YOUR_USERNAME/comfyui-wanvideo-docker:v3 .

# Push to GHCR
docker push ghcr.io/YOUR_USERNAME/comfyui-wanvideo-docker:v3
```

#### Make the Image Public

After pushing, make your package public:
1. Go to your GitHub profile → Packages
2. Click on `comfyui-wanvideo-docker`
3. Click "Package settings" (bottom right)
4. Scroll to "Danger Zone"
5. Click "Change visibility" → Make Public

### Step 2: Create RunPod Template (V3)

1. Go to RunPod.io → Templates → New Template
2. Fill in the details:
   - **Template Name**: ComfyUI WanVideo 2.2 Animate - V3
   - **Container Image**: `ghcr.io/YOUR_USERNAME/comfyui-wanvideo-docker:v3`
   - **Container Disk**: 15 GB
   - **Expose HTTP Ports**: `8188` (ComfyUI), `8888` (JupyterLab - optional)
   - **Expose TCP Ports**: Leave empty

3. Environment Variables (V3 - Configurable Model Downloads):
   ```
   # Download Control (all default to true)
   DOWNLOAD_WANVIDEO_COMPLETE=true      # Master switch - enables all downloads
   DOWNLOAD_DETECTION_MODELS=true       # ViTPose + YOLO (~1.2GB)
   DOWNLOAD_DIFFUSION_MODELS=true       # WanVideo models (~17GB)
   DOWNLOAD_LORAS=true                  # Enhancement LoRAs (~5GB)
   DOWNLOAD_TEXT_ENCODERS=true          # UMT5-XXL (~3GB)
   DOWNLOAD_VAE=true                    # VAE decoders (~1GB)
   DOWNLOAD_CLIP_VISION=true            # CLIP models (~1GB)

   # Optional features
   ENABLE_JUPYTER=false                 # JupyterLab on port 8888
   ```

   **Note**: Setting `DOWNLOAD_WANVIDEO_COMPLETE=true` (default) enables all model downloads. Set individual flags to `false` to skip specific model types.

4. Docker Command: Leave empty (uses /start.sh from image)

### Step 3: Deploy Pod

1. Go to Pods → Deploy
2. Select your template
3. Choose GPU:
   - **RTX 4090** (24GB) - Minimum for FP8
   - **RTX 5090** (32GB) - Recommended
   - **H100** (80GB) - Best performance
   - **A100** (40GB/80GB) - Also works

4. **CRITICAL**: GPU Requirements
   - CUDA driver >= 560 (for CUDA 12.8 support)
   - Check "Additional Filters" → Select CUDA 12.8

5. **CRITICAL**: Attach a Network Volume
   - Create new volume or use existing
   - Mount path: `/workspace/ComfyUI/models`
   - Size: **100GB minimum** (models are ~30GB)

6. Start the pod

### Step 4: First Run - Model Downloads (V3)

1. Wait for pod to start (30-60 seconds)
2. Watch pod logs for automatic model downloads:
   - Progress bars show download status
   - Total download: ~25-30GB
   - Time: 15-25 minutes (depending on network)
3. Models are cached on network volume
4. Subsequent runs: instant (no re-download)

### Step 5: Access ComfyUI

1. Wait for "🚀 Starting ComfyUI..." in logs
2. Click "Connect" → "HTTP Service [8188]"
3. ComfyUI interface loads
4. **VERIFY**: Check WanVideoWrapper nodes load without errors! ✅

## Network Volume Structure (V3)

```
/workspace/ComfyUI/models/       # Network volume mount point
├── detection/                   # Detection models
│   ├── vitpose-l-wholebody.onnx
│   └── yolov10m.onnx
├── diffusion_models/            # Main WanVideo models
│   ├── Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors
│   └── wan2.1_t2v_14B_fp8_scaled.safetensors
├── loras/                       # LoRA models
│   ├── WanAnimate_relight_lora_fp16.safetensors
│   ├── lightx2v_I2V_14B_480p_cfg_step_distill_rank256_bf16.safetensors
│   ├── lightx2v_T2V_14B_cfg_step_distill_v2_lora_rank64_bf16.safetensors
│   └── wan_alpha_2.1_rgba_lora.safetensors
├── text_encoders/               # Text encoders
│   ├── umt5-xxl-enc-bf16.safetensors
│   └── umt5_xxl_fp8_e4m3fn_scaled.safetensors
├── vae/                         # VAE models
│   ├── Wan2_1_VAE_bf16.safetensors
│   ├── wan_alpha_2.1_vae_rgb_channel.safetensors
│   └── wan_alpha_2.1_vae_alpha_channel.safetensors
├── clip_vision/                 # CLIP models
│   └── clip_vision_h.safetensors
├── input/                       # Upload input files here
└── output/                      # Generated outputs saved here
```

## 🔥 COMPREHENSIVE TROUBLESHOOTING GUIDE

### Problem 1: WanVideoWrapper Import Failures (V1-V2)

**Symptoms**:
- ComfyUI starts but WanVideoWrapper nodes missing
- Error: "ModuleNotFoundError: No module named 'peft'"
- Error: "ModuleNotFoundError: No module named 'sentencepiece'"
- Error: "ModuleNotFoundError: No module named 'pyloudnorm'"

**Root Cause**:
WanVideoWrapper's `requirements.txt` was completely skipped during build, causing missing Python dependencies.

**The Fix (V3)**:
```dockerfile
# Dockerfile lines 104-105
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r /workspace/ComfyUI/custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt
```

**Why It Works**:
- PyTorch nightly is installed FIRST (satisfies torch>=2.0.0)
- WanVideoWrapper requirements.txt has NO torch pins
- pip installs missing deps without downgrading PyTorch
- Result: All dependencies present, WanVideoWrapper imports ✅

**Verification**:
```bash
# Inside container
python -c "import peft; import sentencepiece; import pyloudnorm"
# Should complete with no errors
```

### Problem 2: PyTorch Version Downgrades (V1-V2)

**Symptoms**:
- Build starts with PyTorch 2.10 nightly
- After installing dependencies, PyTorch downgrades to 2.7.0
- WanVideoWrapper fails with compatibility errors

**Root Cause (Incorrect)**:
We initially thought WanVideoWrapper requirements.txt pinned torch versions.

**Actual Root Cause**:
Other custom nodes (comfyui_controlnet_aux, etc.) had torch==2.7.0 pins in their requirements.txt

**The Fix (V3)**:
1. Install PyTorch nightly FIRST (Dockerfile:40-43)
2. Install WanVideoWrapper requirements SECOND (Dockerfile:104-105)
3. Skip WanVideoWrapper in custom nodes loop to avoid re-processing (Dockerfile:137)

**Verification**:
```bash
# Inside container
python -c "import torch; print(torch.__version__)"
# Should show: 2.10.0.dev20250924+cu128
```

### Problem 3: Wrong Model URLs and Destinations (V2)

**Symptoms**:
- Models download but ComfyUI can't find them
- Wrong file names (e.g., looking for "v2" files but downloaded "v1")
- Models in wrong directories

**Root Cause**:
V2 start.sh had:
- Incorrect model URLs (pointing to non-existent v2 files)
- Wrong destination paths (custom node dirs instead of /models/)
- Complex env variable logic that didn't match reality

**The Fix (V3)**:
Completely rewrote start.sh based on actual working deployment logs:
- Direct wget downloads (no aria2c complexity)
- Exact URLs from working pod
- Correct destinations matching ComfyUI expectations
- Simplified logic, no env variable flags

**Verification**:
Check start.sh lines 98-208 for correct model download URLs

### Problem 4: diffusers Version Incompatibility (V1)

**Symptoms**:
- Error: "GGUF quantization not supported"
- WanVideoWrapper fails to load GGUF models

**Root Cause**:
diffusers 0.33.0 doesn't support GGUF quantization (added in 0.35+)

**The Fix (V3)**:
```dockerfile
# Dockerfile line 66 - NO VERSION PIN
pip install diffusers  # Gets 0.35.2 with GGUF support
```

**Verification**:
```bash
python -c "from diffusers import __version__; print(__version__)"
# Should show: 0.35.2 or higher
```

### Problem 5: CUDA 12.8 Compatibility (All Versions)

**Symptoms**:
- "CUDA driver version is insufficient"
- PyTorch can't find GPU
- nvidia-smi shows incompatible driver

**Root Cause**:
CUDA 12.8 requires GPU driver >= 560.x

**The Fix**:
On RunPod:
1. Select GPU with driver >= 560
2. Filter for "CUDA 12.8" in Additional Filters
3. Recommended GPUs: RTX 4090/5090, H100, A100 (with new driver)

**Verification**:
```bash
nvidia-smi
# Check "Driver Version" >= 560.x
```

### Problem 6: Model Download Organization Failed (V2)

**Symptoms**:
- Env variables (DOWNLOAD_WANVIDEO=true) didn't work
- Some models downloaded, others didn't
- Inconsistent behavior

**Root Cause**:
Overly complex feature-based download logic with env variables that didn't match actual requirements.

**The Fix (V3)**:
Simplified start.sh to just download ALL required models directly with no configuration:
- No env variables (except optional ENABLE_JUPYTER)
- Every model downloads automatically
- Uses simple wget with direct URLs
- All-or-nothing approach: either works completely or fails visibly

**Verification**:
Check start.sh - no DOWNLOAD_* variables, just direct downloads

## Package Installation Order - CRITICAL

This is the EXACT order that works. DO NOT change it!

### Dockerfile Package Installation Order (Lines 40-148)

1. **PyTorch Nightly** (40-43)
   ```dockerfile
   pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128
   ```
   ✅ Installs PyTorch 2.10.0.dev+cu128

2. **ComfyUI Requirements** (56-57)
   ```dockerfile
   pip install -r /workspace/ComfyUI/requirements.txt
   ```
   ✅ Core ComfyUI dependencies (won't downgrade PyTorch)

3. **Base Dependencies** (61-75)
   ```dockerfile
   pip install triton accelerate transformers diffusers opencv-python ...
   ```
   ✅ diffusers 0.35.2 (no pin = latest with GGUF)

4. **WanVideoWrapper Requirements** (104-105) - THE CRITICAL FIX
   ```dockerfile
   pip install -r /workspace/ComfyUI/custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt
   ```
   ✅ Installs peft, sentencepiece, pyloudnorm, etc.
   ✅ PyTorch stays at nightly (no downgrade!)

5. **Other Custom Nodes** (133-148)
   ```dockerfile
   # Loop through custom nodes, SKIP WanVideoWrapper (already done)
   ```
   ✅ Installs other node requirements

6. **SageAttention** (151-152)
   ```dockerfile
   pip install sageattention || echo "failed"
   ```
   ✅ Optional optimization (fails gracefully if incompatible)

### Why This Order Matters

❌ **WRONG** (V1-V2):
1. PyTorch nightly
2. Other custom nodes (some pin torch==2.7.0)
3. Skip WanVideoWrapper requirements
Result: PyTorch downgrades to 2.7.0, missing dependencies

✅ **CORRECT** (V3):
1. PyTorch nightly
2. ComfyUI base deps
3. WanVideoWrapper requirements (no torch pin!)
4. Other custom nodes (skip WanVideoWrapper)
Result: PyTorch stays nightly, all deps present

## Technical Specifications (V3)

- **Base Image**: nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04
- **Python**: 3.12 in virtual environment
- **PyTorch**: 2.10.0.dev20250924+cu128 (nightly)
- **diffusers**: 0.35.2 (GGUF support)
- **ComfyUI**: Latest from official repo
- **Image Size**: ~8GB
- **Startup Time**:
  - First run: 15-25 mins (model downloads ~30GB)
  - Subsequent: 30-60 seconds (instant)
- **Ports**: 8188 (ComfyUI), 8888 (JupyterLab)
- **Model Downloads**: wget (simple, reliable)

## Updating the Image

### Rebuild and Push V3

```bash
# Rebuild from scratch
docker build --no-cache -t ghcr.io/YOUR_USERNAME/comfyui-wanvideo-docker:v3 .

# Push to GHCR
docker push ghcr.io/YOUR_USERNAME/comfyui-wanvideo-docker:v3
```

### Update RunPod Pod

1. Terminate existing pod
2. Deploy new pod with same template (pulls latest image)
3. Reattach same network volume (keeps models)
4. Models don't re-download (already cached)

## File Structure

```
.
├── Dockerfile                # Main build instructions (V3 fixes)
├── start.sh                  # Startup script (simplified V3)
├── README.md                 # This file (complete guide)
├── RUNPOD_FINAL_CONFIG.md    # RunPod deployment guide
├── V3_CHANGES.md             # Detailed V3 changes
├── .gitignore                # Excluded files (logs, personal notes)
└── .dockerignore             # Build exclusions
```

## Changelog

### V3 (Latest - 2025-10-27) ✅ STABLE

**🔥 CRITICAL FIX**: WanVideoWrapper now imports successfully!

- ✅ Fixed WanVideoWrapper requirements.txt installation
- ✅ PyTorch nightly 2.10+cu128 (preserved, no downgrades)
- ✅ diffusers 0.35.2 (GGUF quantization support)
- ✅ Simplified model downloads (direct URLs, no env vars)
- ✅ All dependencies correctly installed (peft, sentencepiece, etc.)
- ✅ Verified working on RTX 4090/5090, H100
- ✅ Complete troubleshooting guide (this README)
- ✅ Installation order documented and locked
- Image size: ~8GB
- Model downloads: ~30GB
- **Status: Production Ready**

### V2 (2025-10-26) ❌ BROKEN - DO NOT USE

- ❌ WanVideoWrapper import failures (missing dependencies)
- ❌ PyTorch version instability
- ❌ Complex env variable logic that didn't work
- ❌ Wrong model URLs and destinations
- Reduced image size to 5-8GB (good idea)
- Runtime model downloads (good idea)
- **Status: Deprecated - Broken**

### V1 (2025-10-25) ❌ PARTIAL - DEPRECATED

- ✅ Models baked into image (slow but worked)
- ❌ WanVideoWrapper dependencies issues
- ❌ 20GB image size (too large)
- **Status: Deprecated - Use V3**

## Next Steps

1. **Build V3**: `docker build -t ghcr.io/YOUR_USERNAME/comfyui-wanvideo-docker:v3 .`
2. **Push to GHCR**: `docker push ghcr.io/YOUR_USERNAME/comfyui-wanvideo-docker:v3`
3. **Make image public** on GitHub Packages
4. **Create RunPod template** with V3 image
5. **Deploy pod** with network volume (100GB+)
6. **Wait for model downloads** (15-25 mins first time)
7. **Verify WanVideoWrapper imports** ✅
8. **Start generating** WanVideo 2.2 Animate videos!

## Support and Reference Files

### Documentation Files
- **README.md** (this file) - Complete guide with troubleshooting
- **V3_CHANGES.md** - Detailed V3 technical changes
- **RUNPOD_FINAL_CONFIG.md** - RunPod deployment specifics
- **Dockerfile** - Build instructions with V3 fixes
- **start.sh** - Simplified startup with verified model download URLs

### Troubleshooting Steps
1. Check RunPod pod logs for errors
2. Verify GPU driver >= 560 (nvidia-smi)
3. Verify PyTorch version (should be 2.10.0.dev+cu128)
4. Verify models downloaded to /workspace/ComfyUI/models/
5. Check WanVideoWrapper imports: `python -c "import peft"`
6. Review this README's troubleshooting section

## License

This Dockerfile and associated scripts are provided as-is for use with ComfyUI and RunPod.

## Base Template Notice

**This is the V3 base template for all future WanVideo/ComfyUI pods!**

Key principles established:
1. ✅ Always install WanVideoWrapper requirements.txt AFTER PyTorch
2. ✅ Use PyTorch nightly for latest GPU support
3. ✅ Don't pin diffusers version (get latest GGUF support)
4. ✅ Use direct model downloads with wget (simple, reliable)
5. ✅ Document EVERY problem and fix in README
6. ✅ Verify with actual deployment logs

**When creating new variants**:
- Start from this V3 Dockerfile
- Maintain the installation order (critical!)
- Keep the troubleshooting section updated
- Verify model URLs against working deployments
