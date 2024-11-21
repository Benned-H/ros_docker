# Allow overriding default versions of CUDA, Ubuntu, and SAM 2
ARG CUDA_VERSION=12.6.2
ARG UBUNTU_VERSION=24.04

# Construct the base image dynamically bsed on build arguments
FROM nvidia/cuda:${CUDA_VERSION}-cudnn-runtime-ubuntu${UBUNTU_VERSION} AS sam2

# Prevent prompts during package installs
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies of the Segment Anything Model 2 (SAM 2) and its notebook demos
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3-pip \
    # Reference: https://stackoverflow.com/a/63377623
    ffmpeg libsm6 libxext6 && \
    pip3 install --break-system-packages torch torchvision torchaudio \
    "matplotlib>=3.9.1" \
    "jupyter>=1.0.0" \
    "opencv-python>=4.7.0" \
    "eva-decord>=0.6.1" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*