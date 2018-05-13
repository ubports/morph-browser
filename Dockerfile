FROM ubuntu:16.04

RUN apt-get update && \
    apt-get -y --no-install-recommends install \
    pyotherside \
    apt-utils \
    build-essential \
    cmake \
    dpkg-cross \
    fakeroot \
    libc-dev \
    isc-dhcp-client \
    net-tools \
    ifupdown \
    g++-arm-linux-gnueabihf \
    pkg-config-arm-linux-gnueabihf \
    ubuntu-sdk-libs \
    ubuntu-sdk-libs-dev \
    ubuntu-sdk-libs-tools \
    qtbase5-private-dev \
    oxideqt-codecs-extra \
    qml-module-qtsysteminfo \
    libqt5widgets5 \
    qt5-doc \
    language-pack-en \
    click \
    libapparmor-dev \
    # testing QT with python
    xvfb \
    python3-autopilot \
    ubuntu-ui-toolkit-autopilot \
    python-xlib \
    # apps
    webbrowser-app \
    gallery-app
RUN apt-get clean

# Replace 1000 with your user / group id
RUN export uid=1000 gid=1000 && \
    mkdir -p /home/developer && \
    echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:${uid}:" >> /etc/group && \
    mkdir -p /etc/sudoers.d/ && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown ${uid}:${gid} -R /home/developer

USER developer
ENV HOME /home/developer
WORKDIR /home/developer/ubports_build
CMD bash
