# Allow overriding default CUDA version and flavor
# Reference: https://hub.docker.com/r/nvidia/cuda
ARG CUDA_VERSION=12.9.1
ARG CUDA_FLAVOR=cudnn-runtime

# Allow overriding the base image for non-NVIDIA host machines (default uses GPU)
ARG BASE_IMAGE=nvidia/cuda:${CUDA_VERSION}-${CUDA_FLAVOR}-ubuntu20.04

# Install ROS 1 Noetic Desktop-Full onto the base image
FROM ${BASE_IMAGE} AS noetic-desktop-full
ENV ROS_DISTRO=noetic

# Ensure that any failure in a pipe (|) causes the stage to fail
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Stage 1: Install ROS Noetic, using the standard instructions (without sudo)
# Reference: https://wiki.ros.org/noetic/Installation/Ubuntu
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y --no-install-recommends lsb-release curl && \
    sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > \
        /etc/apt/sources.list.d/ros-latest.list' && \
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | \
    apt-key add - && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ros-noetic-desktop-full \
        python3-rosdep \
        python3-rosinstall \
        python3-rosinstall-generator \
        python3-wstool \
        build-essential \
        python3-pip \
        # Provide the `catkin build` command
        # Reference: https://catkin-tools.readthedocs.io/en/latest/installing.html
        python3-catkin-tools && \
        # Clean up layer after using apt-get update
        rm -rf /var/lib/apt/lists/* && apt-get clean

RUN rosdep init && \
    rosdep update && \
    echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc

ENV DISABLE_ROS1_EOL_WARNINGS=1
CMD ["bash"]

# Stage 2 (optional): Install all catkin dependencies of the current workspace
FROM noetic-desktop-full AS install-catkin-deps

# Install the specified list of catkin package dependencies
ARG HOST_DEP_PATH="catkin_package_deps.txt"
ARG BUILD_DEP_PATH="/tmp/${HOST_DEP_PATH}"

COPY "${HOST_DEP_PATH}" "${BUILD_DEP_PATH}"

# Verify that the dependency file exists within the build and is non-empty
RUN if [ ! -f "${BUILD_DEP_PATH}" ]; then \
        echo "Error: ${BUILD_DEP_PATH} not found!" && exit 1; \
    elif [ ! -s "${BUILD_DEP_PATH}" ]; then \
        echo "Error: ${BUILD_DEP_PATH} is empty!" && exit 1; \
    else \
        cat ${BUILD_DEP_PATH}; \
    fi;

# Ensure that any failure in a pipe (|) causes the stage to fail
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Resolve the package dependencies using rosdep
RUN RESOLVED_PACKAGES=""; \
    # Iterate over packages and attempt to resolve each
    while read -r package; do \
        echo "Resolving package '$package'..."; \
        # Redirect stderr to stdout when checking if rosdep resolution fails
        if rosdep_output=$(rosdep resolve "$package" 2>&1); then \
            resolved_package=$(echo "$rosdep_output" | tail -n1); \
            echo "  Package '$package' was resolved as '$resolved_package'"; \
            RESOLVED_PACKAGES+=" $resolved_package"; \
        else \
            echo "  $rosdep_output"; \
        fi; \
    done < "${BUILD_DEP_PATH}"; \
    # Install the aggregated resolved packages
    if [ -n "$RESOLVED_PACKAGES" ]; then \
        echo "Installing packages: $RESOLVED_PACKAGES"; \
        echo "$RESOLVED_PACKAGES" | xargs apt-get install -y --no-install-recommends; \
    else \
        echo "No resolvable packages found"; \
    fi;
