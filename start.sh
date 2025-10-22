#!/bin/bash
set -e

echo "======================================"
echo "ComfyUI WanVideo 2.2 - RunPod Startup"
echo "======================================"

# Function to download models from HuggingFace
download_from_hf() {
    local url=$1
    local output_path=$2
    local filename=$(basename "$output_path")

    if [ -f "$output_path" ]; then
        echo "✓ $filename already exists, skipping..."
        return 0
    fi

    echo "⬇️  Downloading $filename..."
    aria2c -x 16 -s 16 -k 1M "$url" -d "$(dirname "$output_path")" -o "$filename"
    echo "✓ Downloaded $filename"
}

# Function to download models from CivitAI
download_from_civitai() {
    local model_id=$1
    local output_path=$2
    local token=$3

    if [ -z "$token" ]; then
        echo "⚠️  CivitAI token not set, skipping model ID $model_id"
        return 0
    fi

    echo "⬇️  Downloading CivitAI model $model_id..."
    civitdl "https://civitai.com/api/download/models/$model_id" \
        --token "$token" \
        --output "$output_path"
}

# Function to download WanVideo 480p native models
download_480p_models() {
    echo ""
    echo "📦 Downloading WanVideo 480p Native Models..."
    local models_dir="/runpod-volume/models/diffusion_models"
    mkdir -p "$models_dir"

    # Wan 1.3B T2V 480p
    download_from_hf \
        "https://huggingface.co/Kijai/WanVideo-comfyui/resolve/main/wanvideo_t2v_1.3b_480p.safetensors" \
        "$models_dir/wanvideo_t2v_1.3b_480p.safetensors"

    # Wan 14B T2V/I2V 480p
    download_from_hf \
        "https://huggingface.co/Kijai/WanVideo-comfyui/resolve/main/wanvideo_t2v_i2v_14b_480p.safetensors" \
        "$models_dir/wanvideo_t2v_i2v_14b_480p.safetensors"

    echo "✓ 480p models download complete"
}

# Function to download WanVideo 720p native models
download_720p_models() {
    echo ""
    echo "📦 Downloading WanVideo 720p Native Models..."
    local models_dir="/runpod-volume/models/diffusion_models"
    mkdir -p "$models_dir"

    # Wan 1.3B T2V 720p
    download_from_hf \
        "https://huggingface.co/Kijai/WanVideo-comfyui/resolve/main/wanvideo_t2v_1.3b_720p.safetensors" \
        "$models_dir/wanvideo_t2v_1.3b_720p.safetensors"

    # Wan 14B T2V/I2V 720p
    download_from_hf \
        "https://huggingface.co/Kijai/WanVideo-comfyui/resolve/main/wanvideo_t2v_i2v_14b_720p.safetensors" \
        "$models_dir/wanvideo_t2v_i2v_14b_720p.safetensors"

    echo "✓ 720p models download complete"
}

# Function to download Wan Fun and SDXL helper models
download_wan_fun() {
    echo ""
    echo "📦 Downloading Wan Fun and SDXL Helper Models..."
    local models_dir="/runpod-volume/models/diffusion_models"
    local controlnet_dir="/runpod-volume/models/controlnet"
    mkdir -p "$models_dir" "$controlnet_dir"

    # Wan Fun 1.3B
    download_from_hf \
        "https://huggingface.co/Kijai/WanVideo-comfyui/resolve/main/wanfun_1.3b.safetensors" \
        "$models_dir/wanfun_1.3b.safetensors"

    # Wan Fun 14B
    download_from_hf \
        "https://huggingface.co/Kijai/WanVideo-comfyui/resolve/main/wanfun_14b.safetensors" \
        "$models_dir/wanfun_14b.safetensors"

    # SDXL ControlNet for helper workflow
    download_from_hf \
        "https://huggingface.co/xinsir/controlnet-union-sdxl-1.0/resolve/main/diffusion_pytorch_model_promax.safetensors" \
        "$controlnet_dir/controlnet-union-sdxl-promax.safetensors"

    echo "✓ Wan Fun models download complete"
}

# Function to download VACE models
download_vace_models() {
    echo ""
    echo "📦 Downloading Wan VACE Models..."
    local models_dir="/runpod-volume/models/diffusion_models"
    mkdir -p "$models_dir"

    # VACE model
    download_from_hf \
        "https://huggingface.co/Kijai/WanVideo-comfyui/resolve/main/wanvideo_vace.safetensors" \
        "$models_dir/wanvideo_vace.safetensors"

    echo "✓ VACE models download complete"
}

# Function to download CivitAI LoRAs
download_civitai_loras() {
    if [ -z "$LORAS_IDS_TO_DOWNLOAD" ]; then
        return 0
    fi

    echo ""
    echo "📦 Downloading CivitAI LoRAs..."
    local loras_dir="/runpod-volume/models/loras"
    mkdir -p "$loras_dir"

    IFS=',' read -ra IDS <<< "$LORAS_IDS_TO_DOWNLOAD"
    for id in "${IDS[@]}"; do
        id=$(echo "$id" | xargs) # trim whitespace
        download_from_civitai "$id" "$loras_dir" "$civitai_token"
    done

    echo "✓ LoRAs download complete"
}

# Function to download CivitAI Checkpoints
download_civitai_checkpoints() {
    if [ -z "$CHECKPOINT_IDS_TO_DOWNLOAD" ]; then
        return 0
    fi

    echo ""
    echo "📦 Downloading CivitAI Checkpoints..."
    local checkpoints_dir="/runpod-volume/models/diffusion_models"
    mkdir -p "$checkpoints_dir"

    IFS=',' read -ra IDS <<< "$CHECKPOINT_IDS_TO_DOWNLOAD"
    for id in "${IDS[@]}"; do
        id=$(echo "$id" | xargs) # trim whitespace
        download_from_civitai "$id" "$checkpoints_dir" "$civitai_token"
    done

    echo "✓ Checkpoints download complete"
}

# Function to create symlinks if network volume is mounted
setup_model_symlinks() {
    if [ -d "/runpod-volume" ]; then
        echo "RunPod network volume detected at /runpod-volume"

        # Create models directory structure on volume if it doesn't exist
        mkdir -p /runpod-volume/models/diffusion_models
        mkdir -p /runpod-volume/models/text_encoders
        mkdir -p /runpod-volume/models/vae
        mkdir -p /runpod-volume/models/clip_vision
        mkdir -p /runpod-volume/models/loras
        mkdir -p /runpod-volume/models/controlnet
        mkdir -p /runpod-volume/models/sam2
        mkdir -p /runpod-volume/models/upscale_models
        mkdir -p /runpod-volume/models/ipadapter
        mkdir -p /runpod-volume/input
        mkdir -p /runpod-volume/output
        mkdir -p /runpod-volume/workflows

        # Copy pre-downloaded models to volume if they don't exist
        echo "Syncing pre-downloaded models to network volume..."
        if [ -d "/workspace/models/clip_vision" ]; then
            cp -rn /workspace/models/* /runpod-volume/models/ 2>/dev/null || true
        fi

        # Remove local model directories and create symlinks
        echo "Creating symlinks to network volume..."
        rm -rf /workspace/ComfyUI/models
        ln -sf /runpod-volume/models /workspace/ComfyUI/models

        rm -rf /workspace/ComfyUI/input
        ln -sf /runpod-volume/input /workspace/ComfyUI/input

        rm -rf /workspace/ComfyUI/output
        ln -sf /runpod-volume/output /workspace/ComfyUI/output

        echo "Network volume setup complete!"
    else
        echo "No RunPod network volume detected - using local storage"
        # Create symlinks to local directories
        ln -sf /workspace/models /workspace/ComfyUI/models
        ln -sf /workspace/input /workspace/ComfyUI/input
        ln -sf /workspace/output /workspace/ComfyUI/output
    fi
}

# Function to check GPU availability
check_gpu() {
    if command -v nvidia-smi &> /dev/null; then
        echo "GPU Status:"
        nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader
    else
        echo "WARNING: nvidia-smi not found - GPU may not be available"
    fi
}

# Function to display environment info
show_environment() {
    echo ""
    echo "Environment Information:"
    echo "Python: $(python --version)"
    echo "PyTorch: $(python -c 'import torch; print(torch.__version__)')"
    echo "CUDA Available: $(python -c 'import torch; print(torch.cuda.is_available())')"
    if python -c 'import torch; exit(0 if torch.cuda.is_available() else 1)' 2>/dev/null; then
        echo "CUDA Version: $(python -c 'import torch; print(torch.version.cuda)')"
        echo "GPU Count: $(python -c 'import torch; print(torch.cuda.device_count())')"
    fi
    echo ""
}

# Setup symlinks
setup_model_symlinks

# Download models based on environment variables
if [ "$download_480p_native_models" = "true" ]; then
    download_480p_models
fi

if [ "$download_720p_native_models" = "true" ]; then
    download_720p_models
fi

if [ "$download_wan_fun_and_sdxl_helper" = "true" ]; then
    download_wan_fun
fi

if [ "$download_vace" = "true" ]; then
    download_vace_models
fi

# Download CivitAI models if requested
download_civitai_loras
download_civitai_checkpoints

# Check GPU
check_gpu

# Show environment
show_environment

# Change to ComfyUI directory
cd /workspace/ComfyUI

# Optional: Start JupyterLab in background if requested
if [ "$ENABLE_JUPYTER" = "true" ]; then
    echo "Starting JupyterLab on port 8888..."
    jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root \
        --ServerApp.token='' --ServerApp.password='' \
        --ServerApp.allow_origin='*' \
        --ServerApp.base_url=/ &
    echo "JupyterLab started!"
fi

# Start ComfyUI
echo ""
echo "Starting ComfyUI on port 8188..."
echo "Access at: http://localhost:8188"
echo ""

# Start with proper arguments for RunPod
exec python main.py \
    --listen 0.0.0.0 \
    --port 8188 \
    --preview-method auto \
    --use-split-cross-attention \
    --bf16-vae
