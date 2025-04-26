FROM 763104351884.dkr.ecr.ap-northeast-1.amazonaws.com/pytorch-training:2.6.0-gpu-py312-cu126-ubuntu22.04-sagemaker
# FROM 763104351884.dkr.ecr.ap-northeast-1.amazonaws.com/pytorch-training:2.6.0-cpu-py312-ubuntu22.04-sagemaker
# see: https://github.com/aws/deep-learning-containers/blob/master/available_images.md

COPY ./requirements.txt /tmp/

# Install libraries
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

# Uninstall awscli v1 and install awscli v2
RUN /opt/conda/bin/mamba uninstall -y awscli \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -r aws \
    && rm awscliv2.zip

# Add non-root user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Install sudo and add non-root user
RUN apt-get update \
    && groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Switch to non-root user
USER $USERNAME

# Set working directory
WORKDIR /home/$USERNAME/
