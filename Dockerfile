# Multi-stage build for ComfyUI with WanVideo 2.2 Animate support
# V3: Fixed WanVideoWrapper compatibility, Hearmean-style env variables
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

# Install system dependencies and setup Python (matching working reference)
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        python3.12 python3.12-venv python3.12-dev \
        python3-pip \
        curl ffmpeg git aria2 git-lfs wget ninja-build \
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
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip setuptools wheel packaging

# V3 FIX: Install PyTorch nightly with CUDA 12.8 support (proven working)
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --pre torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/nightly/cu128

# Set CUDA environment variables
ENV CUDA_HOME=/usr/local/cuda \
    TORCH_CUDA_ARCH_LIST="7.0 7.5 8.0 8.6 8.9 9.0+PTX"

# Create workspace directory
WORKDIR /workspace

# Clone ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI

# Install ComfyUI requirements
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r /workspace/ComfyUI/requirements.txt

# Install additional Python packages for WanVideo and utilities
# Following Hearmean's proven approach - let dependencies resolve naturally
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install \
    triton \
    accelerate \
    transformers \
    diffusers \
    opencv-python \
    opencv-contrib-python \
    pillow \
    numpy \
    scipy \
    pyyaml \
    jupyterlab \
    comfy-cli \
    gdown

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

# Core WanVideo nodes (using kijai's official wrapper)
RUN git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git

# V3 FIX: Install WanVideoWrapper requirements AFTER PyTorch nightly
# The requirements.txt does NOT pin torch versions - only requires torch>=2.0.0 via accelerate
# Since PyTorch nightly 2.10+ is already installed, pip won't downgrade
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r /workspace/ComfyUI/custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt

# WanAnimate preprocessing nodes
RUN git clone https://github.com/kijai/ComfyUI-WanAnimatePreprocess.git

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

# Configure ComfyUI Manager security settings to allow all channels
RUN mkdir -p /workspace/ComfyUI/custom_nodes/ComfyUI-Manager && \
    echo '{"security_level": "relaxed", "allow_install_from_any_channel": true}' > /workspace/ComfyUI/custom_nodes/ComfyUI-Manager/config.json

# Install custom node dependencies automatically (with better error handling)
# V3 FIX: WanVideoWrapper requirements already installed above, skip in loop to avoid redundancy
RUN for dir in /workspace/ComfyUI/custom_nodes/*; do \
    if [ -d "$dir" ]; then \
        repo_name=$(basename "$dir"); \
        echo "Processing $repo_name"; \
        if [ "$repo_name" != "ComfyUI-WanVideoWrapper" ]; then \
            if [ -f "$dir/requirements.txt" ]; then \
                pip install -r "$dir/requirements.txt" --no-cache-dir || echo "Failed to install requirements for $repo_name"; \
            fi; \
        else \
            echo "WanVideoWrapper requirements already installed above"; \
        fi; \
        if [ -f "$dir/install.py" ]; then \
            cd "$dir" && python install.py || echo "Failed to run install.py for $repo_name"; \
        fi; \
    fi; \
    done

# Install SageAttention (Linux-specific optimization)
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install sageattention || echo "SageAttention install failed (expected on some platforms)"

# V3 OPTIMIZATION: All models now download on first run via start.sh
# This reduces image size from ~20GB to ~5-8GB
# Uses Hearmean-style feature-based environment variables

# V3: Copy startup script only (no runtime downgrades)
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
