FROM 763104351884.dkr.ecr.ap-northeast-1.amazonaws.com/pytorch-training:2.1.0-gpu-py310-cu121-ubuntu20.04-sagemaker
# FROM 763104351884.dkr.ecr.ap-northeast-1.amazonaws.com/pytorch-training:2.1.0-cpu-py310-ubuntu20.04-sagemaker # for cpu
# see: https://github.com/aws/deep-learning-containers/blob/master/available_images.md

WORKDIR /app
COPY ./requirements.txt /tmp/

# install libraries
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

# set up non-root user
ARG USERNAME=user
ARG GROUPNAME=user
ARG UID=1000
ARG GID=1000
ARG PASSWORD=user
RUN groupadd -g $GID $GROUPNAME && \
    useradd -m -s /bin/bash -u $UID -g $GID -G sudo $USERNAME && \
    echo $USERNAME:$PASSWORD | chpasswd && \
    echo "$USERNAME   ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers

# switch to non-root user
USER $USERNAME

# set working directory
WORKDIR /home/$USERNAME/
