FROM 763104351884.dkr.ecr.ap-northeast-1.amazonaws.com/pytorch-training:2.0.1-cpu-py310-ubuntu20.04-sagemaker
WORKDIR /app
COPY ./requirements.txt /tmp/

# install libs
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

# work in container rootless.
ARG USERNAME=user
ARG GROUPNAME=user
ARG UID=1000
ARG GID=1000
ARG PASSWORD=user
RUN groupadd -g $GID $GROUPNAME && \
    useradd -m -s /bin/bash -u $UID -g $GID -G sudo $USERNAME && \
    echo $USERNAME:$PASSWORD | chpasswd && \
    echo "$USERNAME   ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER $USERNAME
WORKDIR /home/$USERNAME/
