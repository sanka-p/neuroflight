FROM ubuntu:24.04 AS base

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y -q --no-install-recommends \
      locales \
      software-properties-common \
      curl \
      && apt -y autoremove \
      && apt clean autoclean \
	    && rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

# Set locale
RUN locale-gen en_US en_US.UTF-8
RUN update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8

# Install ROS2 Jazzy
# https://github.com/gazebosim/ros_gz
RUN add-apt-repository universe
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null
RUN apt update && apt install -y -q --no-install-recommends \
      ros-jazzy-desktop \
      ros-dev-tools \
      && apt -y autoremove \
      && apt clean autoclean \
	    && rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

# Install Gazebo Harmonic
COPY ../tools/PX4-Autopilot/Tools/setup/ubuntu.sh /tmp/ubuntu.sh
COPY ../tools/PX4-Autopilot/Tools/setup/requirements.txt /tmp/requirements.txt
RUN /bin/bash /tmp/ubuntu.sh

# Configure GUI app support
ENV DISPLAY=:0

ENV DEBIAN_FRONTEND=
