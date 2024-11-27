# Minimal Ubuntu image to test GUI support on various host machines
FROM ubuntu:24.04 AS gui-test

RUN apt-get update && \
    apt-get install -y --no-install-recommends x11-apps && \
    rm -rf /var/lib/apt/lists/* && apt-get clean

ENTRYPOINT ["xeyes"]