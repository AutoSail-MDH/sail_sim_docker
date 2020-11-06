
FROM osrf/ros:melodic-desktop-full

ARG DEBIAN_FRONTEND=noninteractive
ARG TERM=xterm

#RUN apt-get update && apt-get install -y software-properties-common && add-apt-repository ppa:deadsnakes/ppa && \
#    apt-get update && apt-get install -y python3.6 python3-dev python3-pip

#RUN ln -sfn /usr/bin/python3.6 /usr/bin/python3 && ln -sfn /usr/bin/python3 /usr/bin/python && ln -sfn /usr/bin/pip3 /usr/bin/pip

RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-utils \
    build-essential \
    libgl1-mesa-dri \
    libgl1-mesa-glx \
    mesa-common-dev \
    mesa-opencl-icd \
    mesa-utils \
    mesa-utils-extra \
    mesa-vulkan-drivers \
    ros-melodic-desktop-full \
    python3-pip \
    gcc gfortran musl-dev \
    python3-setuptools \
    # python-vcstool \
    wget \
    x11-apps \
    && rm -rf /var/lib/apt/lists/*

# Additional ROS dependencies
# in rosdeps:
#   cgal
#   ocl-icd-opencl-dev
#   opencl-headers
# 
# not in rosdeps
#   fftw3
#   libclfft-dev
#   libfftw3-dev
# 
RUN apt-get update && apt-get install -y --no-install-recommends \	
    fftw3 \
    libcgal-dev \
    libclfft-dev \
    libfftw3-dev \
    ocl-icd-opencl-dev \
    opencl-headers \
    ros-melodic-rosbash \
    ros-melodic-rqt-robot-steering \
    ros-melodic-hector-gazebo-plugins \
    ros-melodic-imu-tools \
    ros-melodic-xacro \
    ros-melodic-ros-control \
    ros-melodic-ros-controllers \
    ros-melodic-gazebo-ros-control \
    ros-melodic-rqt \
    ros-melodic-rqt-runtime-monitor \
    ros-melodic-rqt-srv \
    ros-melodic-rqt-image-view \
    ros-melodic-rqt-topic \
    ros-melodic-rqt-reconfigure \
    ros-melodic-rqt-graph \
    ros-melodic-rqt-robot-monitor \
    ros-melodic-rqt-console \
    ros-melodic-rqt-publisher \
    ros-melodic-rqt-logger-level \
    ros-melodic-rqt-plot \
    && rm -rf /var/lib/apt/lists/*

# Install python packages
RUN pip3 install --upgrade \
    setuptools \
    wheel \
    rosdep \
    rospkg \
    pydot \
    pycryptodomex \
    gnupg

RUN pip3 install --upgrade \
    catkin_tools

# Use bash
SHELL ["/bin/bash", "-c"]

# Create a catkin workspace
RUN mkdir -p /catkin_ws/src

# Clone packages into the workspace
WORKDIR /catkin_ws/src
RUN git clone https://github.com/srmainwaring/asv_wave_sim.git -b feature/fft_waves \
  && git clone https://github.com/srmainwaring/asv_sim.git \
  && git clone https://github.com/srmainwaring/rs750.git -b feature/wrsc-devel
#  && git clone https://github.com/AutoSail-MDH/AutoSailROS.git -b control_package

# Configure, build and cleanup
WORKDIR /catkin_ws
RUN source /opt/ros/melodic/setup.bash \
    && catkin init \
    && catkin clean -y \
    && catkin config \
        --extend /opt/ros/melodic \
        --install \
        --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DPYTHON_EXECUTABLE=/usr/bin/python3 \
    && catkin build

COPY ./catkin_ws/src/AutoSailROS /catkin_ws/src/AutoSailROS
RUN catkin build ctrl_pkg sim_helper \
    && rm -rf .catkin_tools .vscode build devel logs src \
    && apt-get update && rosdep install --from-paths . --ignore-src

# Define entrypoint
COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["bash"]
