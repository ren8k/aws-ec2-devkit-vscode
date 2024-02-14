FROM 763104351884.dkr.ecr.ap-northeast-1.amazonaws.com/pytorch-training:2.1.0-gpu-py310-cu121-ubuntu20.04-sagemaker
# FROM 763104351884.dkr.ecr.ap-northeast-1.amazonaws.com/pytorch-training:2.1.0-cpu-py310-ubuntu20.04-sagemaker # for cpu
# see: https://github.com/aws/deep-learning-containers/blob/master/available_images.md

WORKDIR /app
COPY ./requirements.txt /tmp/

# install libraries
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

# add non-root user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN apt-get update \
    && groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME\
    && chmod 0440 /etc/sudoers.d/$USERNAME

# switch to non-root user
USER $USERNAME

# set working directory
WORKDIR /home/$USERNAME/
