# Ubuntu container with OpenGL GUI support, to be run from Docker on macOS
# Tested on macOS 12.7.6 (Intel core)
#
# To build this image, use the command:
#   docker compose --progress plain build glxgears-mac
#
# To run the container with GUI support:
# 1. Open XQuartz using the command:
#   open -a XQuartz
# 2. Within XQuartz > Preferences... > Security, check the boxes:
#   "Authenticate connections" and "Allow connections from network clients"
# 3. If the boxes weren't previously checked, restart XQuartz (close, then re-open)
# 4. Provide xhost access to Docker using the command:
#   xhost +localhost
#
# Then, run this image as a container using:
#   docker compose run --entrypoint bash glxgears-mac
#
# OR:   docker compose up glxgears-mac
FROM ubuntu:24.04 AS glxgears-mac

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
        # Install mesa-utils for `glxgears`
        mesa-utils \
        # Install software-properties-common for `add-apt-repository`
        software-properties-common
    # TODO: Merge back together or apt-get clean etc...

# Add a PPA to the image's package sources to access latest Mesa 3D graphics drivers
RUN add-apt-repository ppa:kisak/kisak-mesa && \
    apt-get update && apt-get -y upgrade
    # apt-get clean && \
    # rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["glxgears"]

# RUN apt-get update && apt-get install ffmpeg libsm6 libxext6  -y
# RUN apt-get install -y libgl1-mesa-dev libosmesa6-dev

# Possibly install the following:
# 1. ffmpeg libsm6 libxext6
# 2. xauth xeyes glx-utils
# Run glxgears command

# docker run --rm -ti -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=$DISPLAY --privileged glxgears-docker glxgears

# docker run --rm -ti -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=$DISPLAY  --privileged glxgears-docker
# --privileged enables direct rendering required for glxgears. Before forwarding the DISPLAY port like above, xhost + might be necessary:

# xhost +
