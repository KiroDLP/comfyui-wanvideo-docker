# Building Locally and Pushing to GHCR

GitHub Actions doesn't have enough disk space for this build (~14GB limit). Build locally instead!

## Prerequisites

- Docker Desktop installed
- 30GB+ free disk space
- GitHub Personal Access Token with `write:packages` permission

## Step 1: Build the Image Locally

```bash
cd D:\Dev\docker

# Build the image (takes 30-60 minutes)
docker build -t comfyui-wanvideo:latest .
```

**Note**: The build downloads ~15GB (CUDA, PyTorch, models). Be patient!

## Step 2: Login to GHCR

```bash
# Replace YOUR_USERNAME with: KiroDLP
# Replace YOUR_TOKEN with your GitHub Personal Access Token
echo YOUR_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin
```

You should see: `Login Succeeded`

## Step 3: Tag and Push to GHCR

```bash
# Tag the image for GHCR
docker tag comfyui-wanvideo:latest ghcr.io/kirodlp/comfyui-wanvideo-docker:latest

# Push to GitHub Container Registry
docker push ghcr.io/kirodlp/comfyui-wanvideo-docker:latest
```

## Step 4: Make the Image Public

1. Go to https://github.com/KiroDLP?tab=packages
2. Click on `comfyui-wanvideo-docker`
3. Click "Package settings" (bottom right)
4. Scroll to "Danger Zone" → "Change visibility"
5. Select "Public" and confirm

## Step 5: Use in RunPod

In your RunPod template, use:
```
ghcr.io/kirodlp/comfyui-wanvideo-docker:latest
```

## Alternative: Use the Build Script

```bash
# Run the interactive script
./build-and-push.sh
```

The script will:
- Guide you through the build process
- Handle login automatically
- Tag and push to GHCR
- Show you the next steps

## Troubleshooting

### Build fails with "no space left on device"
- Free up disk space on your local machine
- Docker needs ~30GB for this build

### "permission denied" when running docker
- On Windows: Make sure Docker Desktop is running
- On Linux: Add yourself to docker group: `sudo usermod -aG docker $USER`

### Push fails with "unauthorized"
- Check your GitHub token has `write:packages` permission
- Make sure you're logged in: `docker login ghcr.io`

## Building on Windows

If you're on Windows and don't have WSL2, you can still build:

```powershell
# Open PowerShell as Administrator
cd D:\Dev\docker

# Build
docker build -t comfyui-wanvideo:latest .

# Login (replace with your info)
docker login ghcr.io -u KiroDLP

# Tag and push
docker tag comfyui-wanvideo:latest ghcr.io/kirodlp/comfyui-wanvideo-docker:latest
docker push ghcr.io/kirodlp/comfyui-wanvideo-docker:latest
```

## Can I build directly on RunPod?

**Yes!** You can build directly on a RunPod instance:

### Option 1: Build on RunPod GPU Pod

1. Deploy a basic GPU pod (any GPU, even cheap ones work for building)
2. SSH into the pod
3. Install git and clone your repo:
   ```bash
   apt-get update && apt-get install -y git
   git clone https://github.com/KiroDLP/comfyui-wanvideo-docker.git
   cd comfyui-wanvideo-docker
   ```
4. Build the image:
   ```bash
   docker build -t ghcr.io/kirodlp/comfyui-wanvideo-docker:latest .
   ```
5. Login and push:
   ```bash
   echo YOUR_TOKEN | docker login ghcr.io -u KiroDLP --password-stdin
   docker push ghcr.io/kirodlp/comfyui-wanvideo-docker:latest
   ```
6. Terminate the pod

**Pros**: Plenty of disk space, fast network
**Cons**: Costs a few dollars for the build time (~1-2 hours)

### Option 2: Use RunPod's Dockerfile Build Feature

Some RunPod templates support building from a Dockerfile directly. Check RunPod docs for the latest features.

## Next Steps

Once your image is pushed to GHCR:
1. Make it public (see Step 4 above)
2. Create a RunPod template with `ghcr.io/kirodlp/comfyui-wanvideo-docker:latest`
3. Deploy a pod with your template
4. Upload WanVideo models to the network volume
5. Start generating!
