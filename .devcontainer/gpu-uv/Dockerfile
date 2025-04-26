FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu22.04

# Install uv by copying the binary from the official distroless Docker image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install awscli v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
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

# add ll alias
# RUN echo 'alias ll="ls -la"' >> ~/.bash_aliases
