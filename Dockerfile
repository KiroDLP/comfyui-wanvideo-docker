# Multi-stage build for ComfyUI with WanVideo 2.2 support
# Optimized for RunPod deployment

# =============================================================================
# Stage 1: Base - CUDA, Python, PyTorch, ComfyUI
# =============================================================================
FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04 AS base

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_PREFER_BINARY=1 \
    CMAKE_BUILD_PARALLEL_LEVEL=8

# Install system dependencies and setup Python (matching reference implementation)
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        python3.12 python3.12-venv python3.12-dev \
        python3-pip \
        curl ffmpeg git aria2 git-lfs wget \
        libgl1 libglib2.0-0 build-essential && \
    \
    ln -sf /usr/bin/python3.12 /usr/bin/python && \
    ln -sf /usr/bin/pip3 /usr/bin/pip && \
    \
    python3.12 -m venv /opt/venv && \
    \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Activate virtual environment
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Upgrade pip and install core packages
RUN pip install --upgrade pip setuptools wheel packaging && \
    rm -rf /root/.cache/pip

# Install PyTorch nightly with CUDA 12.8 support (matching reference)
RUN pip install --pre torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/nightly/cu128 && \
    rm -rf /root/.cache/pip

# Set CUDA environment variables
ENV CUDA_HOME=/usr/local/cuda \
    TORCH_CUDA_ARCH_LIST="7.5 8.0 8.6 8.9 9.0+PTX"

# Create workspace directory
WORKDIR /workspace

# Clone ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI

# Install ComfyUI requirements and additional packages in one step
RUN pip install -r /workspace/ComfyUI/requirements.txt && \
    pip install \
    xformers \
    accelerate \
    transformers \
    opencv-python \
    pillow \
    numpy \
    scipy \
    pyyaml \
    jupyterlab \
    comfy-cli && \
    rm -rf /root/.cache/pip

# =============================================================================
# Stage 2: Final - Custom Nodes, Models, Configuration
# =============================================================================
FROM base AS final

# Create model directories
RUN mkdir -p /workspace/models/diffusion_models \
    /workspace/models/text_encoders \
    /workspace/models/vae \
    /workspace/models/clip_vision \
    /workspace/models/loras \
    /workspace/models/controlnet \
    /workspace/models/sam2 \
    /workspace/models/upscale_models \
    /workspace/models/ipadapter \
    /workspace/input \
    /workspace/output

# Install custom nodes for WanVideo 2.2
WORKDIR /workspace/ComfyUI/custom_nodes

# Core WanVideo nodes
RUN git clone https://github.com/logtd/ComfyUI-WanVideoWrapper.git && \
    git clone https://github.com/logtd/ComfyUI-WanAnimatePreprocess.git

# Video and image processing nodes
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git && \
    git clone https://github.com/kijai/ComfyUI-segment-anything-2.git && \
    git clone https://github.com/kijai/ComfyUI-KJNodes.git

# Additional utility nodes
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git && \
    git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git && \
    git clone https://github.com/cubiq/ComfyUI_IPAdapter_plus.git && \
    git clone https://github.com/cubiq/ComfyUI_essentials.git && \
    git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git && \
    git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git && \
    git clone https://github.com/city96/ComfyUI-GGUF.git && \
    git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git && \
    git clone https://github.com/chflame163/ComfyUI_LayerStyle.git

# Install custom node dependencies automatically
RUN for dir in /workspace/ComfyUI/custom_nodes/*; do \
    if [ -d "$dir" ]; then \
        echo "Processing $dir"; \
        if [ -f "$dir/requirements.txt" ]; then \
            pip install -r "$dir/requirements.txt" || echo "Failed to install requirements for $dir"; \
        fi; \
        if [ -f "$dir/install.py" ]; then \
            cd "$dir" && python install.py || echo "Failed to run install.py for $dir"; \
        fi; \
    fi; \
    done

# Install SageAttention and Triton (Linux-specific optimization)
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install sageattention || echo "SageAttention install failed (expected on some platforms)" && \
    pip install triton || echo "Triton install failed (expected on some platforms)"

# Download essential models using aria2c (parallel downloads)
WORKDIR /workspace/models

# CLIP Vision models
RUN aria2c -x16 -s16 -k1M \
    https://huggingface.co/h94/IP-Adapter/resolve/main/models/image_encoder/model.safetensors \
    -d /workspace/models/clip_vision -o CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors

RUN aria2c -x16 -s16 -k1M \
    https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/image_encoder/model.safetensors \
    -d /workspace/models/clip_vision -o CLIP-ViT-bigG-14-laion2B-39B-b160k.safetensors

# IP-Adapter models
RUN aria2c -x16 -s16 -k1M \
    https://huggingface.co/h94/IP-Adapter/resolve/main/models/ip-adapter_sd15.safetensors \
    -d /workspace/models/ipadapter -o ip-adapter_sd15.safetensors

RUN aria2c -x16 -s16 -k1M \
    https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter_sdxl_vit-h.safetensors \
    -d /workspace/models/ipadapter -o ip-adapter_sdxl_vit-h.safetensors

# Upscale models
RUN aria2c -x16 -s16 -k1M \
    https://huggingface.co/gemasai/4x_LSDIR/resolve/main/4xLSDIR.pth \
    -d /workspace/models/upscale_models -o 4xLSDIR.pth

# Copy startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Set working directory
WORKDIR /workspace/ComfyUI

# Expose ports
# 8188 - ComfyUI web interface (RunPod standard)
# 8888 - JupyterLab (optional debugging)
EXPOSE 8188 8888

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8188/ || exit 1

# Start the service
CMD ["/start.sh"]
