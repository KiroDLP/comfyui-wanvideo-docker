#!/bin/bash
set -e

echo "======================================"
echo "ComfyUI WanVideo 2.2 - RunPod Startup"
echo "======================================"

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
