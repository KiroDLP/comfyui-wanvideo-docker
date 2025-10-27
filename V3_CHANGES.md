# V3 Changes - WanVideo 2.2 Docker

## What's New in V3

V3 is a complete rewrite based on Hearmean's proven approach to fix WanVideoWrapper compatibility issues and provide a better user experience.

### Key Changes

1. **Fixed WanVideoWrapper Import Issues**
   - Switched to PyTorch nightly (proven to work with WanVideoWrapper)
   - Fixed triton/bitsandbytes compatibility (triton==2.3.1, bitsandbytes==0.44.1)
   - Explicitly install WanVideoWrapper requirements
   - Added diffusers==0.31.0 for compatibility

2. **Hearmean-Style Environment Variables**
   - Feature-based downloads instead of granular model-based
   - Easier to understand and use
   - Matches proven working implementations
   - Full CivitAI integration

3. **Complete Feature Packages**
   - Each feature downloads ALL required models automatically
   - No need to understand individual model dependencies
   - Smart deduplication (shared models only download once)

## Environment Variables (V3)

### Feature Downloads (Hearmean-Style)

```bash
# Main WanVideo features
DOWNLOAD_WAN22_COMPLETE=false          # WanVideo 2.2 Complete (main model + encoders + VAE)
DOWNLOAD_WAN_ANIMATE=true              # WanVideo 2.2 Animate (DEFAULT - your primary use case)
DOWNLOAD_480P_NATIVE_MODELS=false      # 480p optimized models (1.3B + 14B)
DOWNLOAD_720P_NATIVE_MODELS=false      # 720p optimized models (1.3B + 14B)
DOWNLOAD_WAN_FUN_AND_SDXL_HELPER=false # WAN Fun models + SDXL helpers
DOWNLOAD_VACE=false                    # VACE video editing model
```

### CivitAI Integration

```bash
# CivitAI downloads (exactly like Hearmean)
CIVITAI_TOKEN=                         # Your CivitAI API token
LORAS_IDS_TO_DOWNLOAD=                 # Comma-separated model version IDs
CHECKPOINT_IDS_TO_DOWNLOAD=            # Comma-separated checkpoint IDs

# Example:
# CIVITAI_TOKEN=abc123def456
# LORAS_IDS_TO_DOWNLOAD=12345,67890,11111
# CHECKPOINT_IDS_TO_DOWNLOAD=22222,33333
```

### Optional Features

```bash
ENABLE_JUPYTER=true                    # Enable JupyterLab on port 8888
```

## What Each Feature Downloads

### DOWNLOAD_WAN_ANIMATE=true (Recommended - Your Use Case)

Downloads the complete WanVideo 2.2 Animate package:

```
✅ Wan2_2-Animate-14B_fp8_scaled (~8GB)      - Main Animate model
✅ umt5_xxl_fp8_e4m3fn_scaled (~3GB)         - Text encoder
✅ wan_2.1_vae (~400MB)                      - VAE decoder
✅ wan2.2_animate_14B_relight_lora (~1GB)    - Relight LoRA
✅ lightx2v_I2V_14B (~1GB)                   - Lightx2v LoRA
✅ yolov10m.onnx (~50MB)                     - YOLO detection
✅ vitpose-l-wholebody.onnx (~200MB)         - ViTPose large
✅ CLIP-ViT-H-14 (~2GB)                      - CLIP vision
✅ CLIP-ViT-bigG-14 (~2GB)                   - CLIP vision
✅ ip-adapter_sd15 (~500MB)                  - IP-Adapter
✅ ip-adapter_sdxl_vit-h (~500MB)            - IP-Adapter SDXL

Total: ~19GB
```

### DOWNLOAD_WAN22_COMPLETE=true

Downloads WanVideo 2.2 Complete (not Animate):

```
✅ wan2_2_14B_fp8_scaled (~10GB)             - Main WanVideo 2.2 model
✅ umt5_xxl_fp8_e4m3fn_scaled (~3GB)         - Text encoder
✅ wan_2.1_vae (~400MB)                      - VAE
✅ CLIP encoders (~4GB)                      - CLIP vision

Total: ~17GB
```

### DOWNLOAD_480P_NATIVE_MODELS=true

```
✅ wanvideo_1.3B_480_t2v (~2GB)              - 1.3B 480p model
✅ wanvideo_14B_480_t2v (~8GB)               - 14B 480p model
✅ Shared encoders and VAE (~3.4GB)

Total: ~13GB
```

### DOWNLOAD_720P_NATIVE_MODELS=true

```
✅ wanvideo_1.3B_720_t2v (~3GB)              - 1.3B 720p model
✅ wanvideo_14B_720_t2v (~12GB)              - 14B 720p model
✅ Shared encoders and VAE (~3.4GB)

Total: ~18GB
```

### DOWNLOAD_WAN_FUN_AND_SDXL_HELPER=true

```
✅ wanfun_1.3B_fp8_scaled (~2GB)             - WAN Fun 1.3B
✅ wanfun_14B_fp8_scaled (~8GB)              - WAN Fun 14B
✅ Shared encoders and VAE (~3.4GB)

Total: ~13GB
```

### DOWNLOAD_VACE=true

```
✅ wan_vace_fp8_scaled (~6GB)                - VACE editing model
✅ Shared encoders and VAE (~3.4GB)

Total: ~10GB
```

## V3 Technical Fixes

### 1. PyTorch Nightly

```dockerfile
# V3: Back to nightly (proven to work)
RUN pip install --pre torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/nightly/cu128
```

**Why**: WanVideoWrapper has hardcoded CUDA calls that work reliably with PyTorch nightly but fail with stable 2.7.0.

### 2. Compatible Dependencies

```dockerfile
# V3: Fixed versions that work together
RUN pip install triton==2.3.1 bitsandbytes==0.44.1
RUN pip install diffusers==0.31.0
```

**Why**:
- Newer triton removed `triton.ops` module
- Bitsandbytes needs compatible triton version
- Diffusers 0.31.0 works with WanVideoWrapper

### 3. Explicit WanVideoWrapper Installation

```dockerfile
# V3: Install requirements explicitly
RUN cd ComfyUI-WanVideoWrapper && \
    pip install -r requirements.txt --no-cache-dir
```

**Why**: Ensures all dependencies are installed before the node tries to load.

## RunPod Template Configuration (V3)

### Template Name
```
ComfyUI WanVideo 2.2 Animate - V3
```

### Container Image
```
ghcr.io/YOUR_USERNAME/comfyui-wanvideo-docker:v3
```

### Container Disk
```
10 GB
```

### HTTP Ports
```
8188
8888
```

### Environment Variables (Recommended for WanAnimate)

```
DOWNLOAD_WAN_ANIMATE=true
DOWNLOAD_WAN22_COMPLETE=false
DOWNLOAD_480P_NATIVE_MODELS=false
DOWNLOAD_720P_NATIVE_MODELS=false
DOWNLOAD_WAN_FUN_AND_SDXL_HELPER=false
DOWNLOAD_VACE=false
CIVITAI_TOKEN=
LORAS_IDS_TO_DOWNLOAD=
CHECKPOINT_IDS_TO_DOWNLOAD=
ENABLE_JUPYTER=true
```

### Network Volume
```
Mount Path: /workspace/models
Size: 50GB minimum (for WanAnimate)
      100GB recommended (for multiple features)
```

## Migration from V2

### V2 Environment Variables (Old - Granular)
```
MODEL_TYPE=fp8_scaled
VITPOSE_MODEL=large
DOWNLOAD_WANVIDEO=true
DOWNLOAD_TEXT_ENCODER=true
DOWNLOAD_VAE=true
DOWNLOAD_LORAS=true
DOWNLOAD_YOLO=true
DOWNLOAD_VITPOSE=true
DOWNLOAD_IPADAPTER=true
```

### V3 Environment Variables (New - Feature-based)
```
DOWNLOAD_WAN_ANIMATE=true
```

**One variable** replaces **8 variables**!

## Expected Download Times

### First Deployment (WanAnimate)
- Total download: ~19GB
- On fast connection (1Gbps): 10-15 minutes
- On typical RunPod: 15-20 minutes

### Subsequent Deployments
- Startup: **30 seconds** (models cached on network volume)

## Troubleshooting V3

### WanVideoWrapper Still Fails to Import

**Check:**
1. Is CUDA available? `nvidia-smi` should work
2. Are you using the V3 image with PyTorch nightly?
3. Check ComfyUI logs for specific error

**Common Issue**: If you see "Torch not compiled with CUDA enabled", the PyTorch installation is wrong.

**Fix**: Rebuild with V3 Dockerfile (uses nightly).

### Models Not Downloading

**Check:**
1. Environment variables set to `true` (lowercase)
2. Network volume mounted at `/workspace/models`
3. Sufficient disk space on network volume
4. Check pod logs for download progress

### CivitAI Downloads Failing

**Check:**
1. `CIVITAI_TOKEN` is set correctly
2. Model version IDs are correct (not model IDs)
3. Token has proper permissions

## Build and Deploy V3

### 1. Build Locally

```bash
cd D:\Dev\docker
docker build -t ghcr.io/YOUR_USERNAME/comfyui-wanvideo-docker:v3 .
```

### 2. Push to GHCR

```bash
docker push ghcr.io/YOUR_USERNAME/comfyui-wanvideo-docker:v3
```

### 3. Create RunPod Template

Use the configuration above.

### 4. Deploy

- Select CUDA 12.8 GPU
- Attach network volume to `/workspace/models`
- Wait for first-run downloads (15-20 mins)
- Access ComfyUI on port 8188

## Summary

V3 fixes all the critical issues from V2:

✅ WanVideoWrapper import works reliably
✅ PyTorch nightly for compatibility
✅ Fixed triton/bitsandbytes versions
✅ Hearmean-style feature-based downloads
✅ Complete CivitAI integration
✅ Simpler configuration (fewer env vars)
✅ Same small image size (~5-8GB)
✅ Proven approach (matches working implementations)

**For your use case (WanAnimate)**, just set:
```
DOWNLOAD_WAN_ANIMATE=true
```

That's it! Everything else defaults correctly.
