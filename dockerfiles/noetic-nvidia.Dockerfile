### Dockerfile for ROS 1 Noetic + Spot dependencies with NVIDIA GPU Support ###

# Set the image's default CUDA version and flavor
# Reference: https://hub.docker.com/r/nvidia/cuda
ARG CUDA_VERSION=12.6.3
ARG CUDA_FLAVOR=runtime

ARG BASE_IMAGE=nvidia/cuda:${CUDA_VERSION}-${CUDA_FLAVOR}-ubuntu20.04

# Install ROS 1 Noetic Desktop (not full) onto the base image
FROM ${BASE_IMAGE} AS noetic-desktop

# Ensure that any failure in a pipe (|) causes the stage to fail
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install general utilities to enable installing ROS
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        python3-pip \
        python-is-python3 \
        git \
        lsb-release \
        curl && \
    # Clean up layer after using apt-get update
    rm -rf /var/lib/apt/lists/* && apt-get clean

# Stage 1: Install ROS Noetic, using the standard instructions (without sudo)
# Reference: https://wiki.ros.org/noetic/Installation/Ubuntu
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > \
        /etc/apt/sources.list.d/ros-latest.list' && \
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | \
        apt-key add - && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ros-noetic-desktop \
        python3-rosdep \
        python3-rosinstall \
        python3-rosinstall-generator \
        python3-wstool \
        build-essential \
        # Provide the `catkin build` command
        # Reference: https://catkin-tools.readthedocs.io/en/latest/installing.html
        python3-catkin-tools && \
    # Clean up layer after using apt-get update
    rm -rf /var/lib/apt/lists/* && apt-get clean

# Install uv for in-container dependency management
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install additional ROS dependencies not included in ROS Desktop
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ros-noetic-moveit \
        ros-noetic-trac-ik \
        ros-noetic-sensor-filters \
        ros-noetic-navigation \
        ros-noetic-rtabmap \
        ros-noetic-joint-state-publisher \
        ros-noetic-joint-state-publisher-gui \
        ros-noetic-robot-state-publisher \
        ros-noetic-twist-mux \
        ros-noetic-teleop-twist-joy \
        ros-noetic-interactive-marker-twist-server \
        ros-noetic-fiducial-msgs \
        ros-noetic-velodyne-description \
        ros-noetic-velodyne-pointcloud \
        ros-noetic-point-cloud2-filters \
        ros-noetic-robot-body-filter && \
    # Clean up layer after using apt-get update
    rm -rf /var/lib/apt/lists/* && apt-get clean

# Source ROS in all terminals
RUN echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc
ENV DISABLE_ROS1_EOL_WARNINGS=1

# Clone and build the ROS wrapper for RTAB-Map to support multiple RGB-D cameras
WORKDIR /docker/rtabmap_ws/src
RUN git clone --depth 1 --branch noetic-devel https://github.com/introlab/rtabmap_ros

# Another layer to add ROS dependencies required by RTAB-Map
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ros-noetic-image-geometry \
        ros-noetic-apriltag-ros \
        ros-noetic-grid-map && \
    # Clean up layer after using apt-get update
    rm -rf /var/lib/apt/lists/* && apt-get clean

# Build RTAB-Map with the RTABMAP_SYNC_MULTI_RGBD flag
# Reference: https://github.com/introlab/rtabmap_ros/issues/453
WORKDIR /docker/rtabmap_ws
RUN catkin config --extend "/opt/ros/noetic" --cmake-args -DCMAKE_BUILD_TYPE=Release && \
    catkin build rtabmap_ros -DRTABMAP_SYNC_MULTI_RGBD=ON
VOLUME /docker/rtabmap_ws

# Source the rtabmap workspace in all terminals
RUN echo "source /docker/rtabmap_ws/devel/setup.bash" >> ~/.bashrc

RUN python -m pip install -U pip setuptools wheel importlib_metadata==4.13.0

CMD ["bash"]

# Finalize the default working directory for the image
WORKDIR /docker/spot_skills
