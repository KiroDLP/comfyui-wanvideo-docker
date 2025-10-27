#!/bin/bash
set -e

echo "================================================"
echo "ComfyUI WanVideo 2.2 Animate - V3 Startup"
echo "================================================"
echo ""

# ============================================================================
# ENVIRONMENT VARIABLES - Model Download Control
# ============================================================================
# Based on verified working deployment

MODEL_BASE="/workspace/ComfyUI/models"

# Download control flags
DOWNLOAD_WANVIDEO_COMPLETE=${DOWNLOAD_WANVIDEO_COMPLETE:-true}  # All models (default: true)
DOWNLOAD_DETECTION_MODELS=${DOWNLOAD_DETECTION_MODELS:-true}   # ViTPose + YOLO
DOWNLOAD_DIFFUSION_MODELS=${DOWNLOAD_DIFFUSION_MODELS:-true}   # Main WanVideo models
DOWNLOAD_LORAS=${DOWNLOAD_LORAS:-true}                          # LoRA enhancement models
DOWNLOAD_TEXT_ENCODERS=${DOWNLOAD_TEXT_ENCODERS:-true}          # UMT5-XXL encoders
DOWNLOAD_VAE=${DOWNLOAD_VAE:-true}                              # VAE decoders
DOWNLOAD_CLIP_VISION=${DOWNLOAD_CLIP_VISION:-true}              # CLIP vision models

# Optional features
ENABLE_JUPYTER=${ENABLE_JUPYTER:-false}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

download_if_missing() {
    local url=$1
    local output_dir=$2
    local output_file=$3
    local full_path="$output_dir/$output_file"

    if [ -f "$full_path" ]; then
        echo "  ✓ $output_file already exists, skipping"
        return 0
    fi

    echo "  ⬇️  Downloading $output_file..."
    mkdir -p "$output_dir"

    if wget -q --show-progress "$url" -O "$full_path"; then
        echo "  ✅ Downloaded $output_file"
        return 0
    else
        echo "  ❌ Failed to download $output_file"
        return 1
    fi
}

# ============================================================================
# GPU CHECK
# ============================================================================

echo "🖥️  GPU Status:"
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader
else
    echo "  ⚠️  nvidia-smi not found - GPU may not be available"
fi
echo ""

# ============================================================================
# ENVIRONMENT INFO
# ============================================================================

echo "🐍 Environment Information:"
echo "  Python: $(python --version)"
echo "  PyTorch: $(python -c 'import torch; print(torch.__version__)')"
echo "  CUDA Available: $(python -c 'import torch; print(torch.cuda.is_available())')"

if python -c 'import torch; exit(0 if torch.cuda.is_available() else 1)' 2>/dev/null; then
    echo "  CUDA Version: $(python -c 'import torch; print(torch.version.cuda)')"
    echo "  GPU Count: $(python -c 'import torch; print(torch.cuda.device_count())')"
fi
echo ""

# ============================================================================
# MODEL DOWNLOADS - Conditional Based on Environment Variables
# ============================================================================

# Override individual flags if DOWNLOAD_WANVIDEO_COMPLETE=true
if [ "$DOWNLOAD_WANVIDEO_COMPLETE" = "true" ]; then
    DOWNLOAD_DETECTION_MODELS=true
    DOWNLOAD_DIFFUSION_MODELS=true
    DOWNLOAD_LORAS=true
    DOWNLOAD_TEXT_ENCODERS=true
    DOWNLOAD_VAE=true
    DOWNLOAD_CLIP_VISION=true
fi

echo "📦 WanVideo 2.2 Animate Model Downloads"
echo "  Configuration:"
echo "    Complete Package: $DOWNLOAD_WANVIDEO_COMPLETE"
echo "    Detection Models: $DOWNLOAD_DETECTION_MODELS"
echo "    Diffusion Models: $DOWNLOAD_DIFFUSION_MODELS"
echo "    LoRAs: $DOWNLOAD_LORAS"
echo "    Text Encoders: $DOWNLOAD_TEXT_ENCODERS"
echo "    VAE: $DOWNLOAD_VAE"
echo "    CLIP Vision: $DOWNLOAD_CLIP_VISION"
echo ""

# Create all necessary directories
mkdir -p "$MODEL_BASE/detection"
mkdir -p "$MODEL_BASE/diffusion_models"
mkdir -p "$MODEL_BASE/loras"
mkdir -p "$MODEL_BASE/text_encoders"
mkdir -p "$MODEL_BASE/vae"
mkdir -p "$MODEL_BASE/clip_vision"
mkdir -p "$MODEL_BASE/input"
mkdir -p "$MODEL_BASE/output"

# ============================================================================
# Detection Models (for WanAnimate preprocessing)
# ============================================================================

if [ "$DOWNLOAD_DETECTION_MODELS" = "true" ]; then
    echo "📥 Detection Models:"

    download_if_missing \
        "https://huggingface.co/JunkyByte/easy_ViTPose/resolve/main/onnx/wholebody/vitpose-l-wholebody.onnx" \
        "$MODEL_BASE/detection" \
        "vitpose-l-wholebody.onnx"

    download_if_missing \
        "https://huggingface.co/Wan-AI/Wan2.2-Animate-14B/resolve/main/process_checkpoint/det/yolov10m.onnx" \
        "$MODEL_BASE/detection" \
        "yolov10m.onnx"

    echo ""
fi

# ============================================================================
# Diffusion Models (Main models)
# ============================================================================

if [ "$DOWNLOAD_DIFFUSION_MODELS" = "true" ]; then
    echo "📥 Diffusion Models:"

    # WanVideo 2.2 Animate 14B (FP8 quantized - 17GB)
    download_if_missing \
        "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/Wan22Animate/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors" \
        "$MODEL_BASE/diffusion_models" \
        "Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors"

    # WanVideo 2.1 T2V 14B (FP8 quantized - alternative model)
    download_if_missing \
        "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_t2v_14B_fp8_scaled.safetensors" \
        "$MODEL_BASE/diffusion_models" \
        "wan2.1_t2v_14B_fp8_scaled.safetensors"

    echo ""
fi

# ============================================================================
# LoRAs (Enhancement models)
# ============================================================================

if [ "$DOWNLOAD_LORAS" = "true" ]; then
    echo "📥 LoRA Models:"

    download_if_missing \
        "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Wan22_relight/WanAnimate_relight_lora_fp16.safetensors" \
        "$MODEL_BASE/loras" \
        "WanAnimate_relight_lora_fp16.safetensors"

    download_if_missing \
        "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank256_bf16.safetensors" \
        "$MODEL_BASE/loras" \
        "lightx2v_I2V_14B_480p_cfg_step_distill_rank256_bf16.safetensors"

    download_if_missing \
        "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_T2V_14B_cfg_step_distill_v2_lora_rank64_bf16.safetensors" \
        "$MODEL_BASE/loras" \
        "lightx2v_T2V_14B_cfg_step_distill_v2_lora_rank64_bf16.safetensors"

    download_if_missing \
        "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/loras/wan_alpha_2.1_rgba_lora.safetensors" \
        "$MODEL_BASE/loras" \
        "wan_alpha_2.1_rgba_lora.safetensors"

    echo ""
fi

# ============================================================================
# Text Encoders
# ============================================================================

if [ "$DOWNLOAD_TEXT_ENCODERS" = "true" ]; then
    echo "📥 Text Encoders:"

    download_if_missing \
        "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5-xxl-enc-bf16.safetensors" \
        "$MODEL_BASE/text_encoders" \
        "umt5-xxl-enc-bf16.safetensors"

    download_if_missing \
        "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
        "$MODEL_BASE/text_encoders" \
        "umt5_xxl_fp8_e4m3fn_scaled.safetensors"

    echo ""
fi

# ============================================================================
# VAE Models
# ============================================================================

if [ "$DOWNLOAD_VAE" = "true" ]; then
    echo "📥 VAE Models:"

    download_if_missing \
        "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors" \
        "$MODEL_BASE/vae" \
        "Wan2_1_VAE_bf16.safetensors"

    download_if_missing \
        "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_alpha_2.1_vae_rgb_channel.safetensors" \
        "$MODEL_BASE/vae" \
        "wan_alpha_2.1_vae_rgb_channel.safetensors"

    download_if_missing \
        "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_alpha_2.1_vae_alpha_channel.safetensors" \
        "$MODEL_BASE/vae" \
        "wan_alpha_2.1_vae_alpha_channel.safetensors"

    echo ""
fi

# ============================================================================
# CLIP Vision
# ============================================================================

if [ "$DOWNLOAD_CLIP_VISION" = "true" ]; then
    echo "📥 CLIP Vision:"

    download_if_missing \
        "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" \
        "$MODEL_BASE/clip_vision" \
        "clip_vision_h.safetensors"

    echo ""
fi

echo "✅ Model download phase complete!"
echo ""

# ============================================================================
# OPTIONAL: START JUPYTERLAB
# ============================================================================

if [ "$ENABLE_JUPYTER" = "true" ]; then
    echo "🔬 Starting JupyterLab on port 8888..."
    jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root \
        --ServerApp.token='' --ServerApp.password='' \
        --ServerApp.allow_origin='*' \
        --ServerApp.base_url=/ &
    echo "  ✓ JupyterLab started!"
    echo ""
fi

# ============================================================================
# APPLY COMPATIBILITY ENVIRONMENT VARIABLES
# ============================================================================

echo "🔧 Applying compatibility environment variables..."
export TORCHAUDIO_USE_BACKEND_DISPATCH=1
export TORCHAUDIO_USE_SOX=0
export XFORMERS_MORE_DETAILS=1
export XFORMERS_DISABLED=0
export FLASH_ATTENTION_FORCE_BUILD=0
export FLASH_ATTENTION_SKIP_CUDA_BUILD=1
export CUDA_VISIBLE_DEVICES=0
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
export TORCH_CUDNN_V8_API_ENABLED=1
echo "  ✓ Environment configured"
echo ""

# ============================================================================
# START COMFYUI
# ============================================================================

echo "================================================"
echo "🚀 Starting ComfyUI..."
echo "================================================"
echo "  Access at: http://localhost:8188"
echo ""

cd /workspace/ComfyUI
exec python main.py \
    --listen 0.0.0.0 \
    --port 8188 \
    --preview-method auto \
    --use-split-cross-attention \
    --bf16-vae
