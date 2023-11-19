FROM nvcr.io/nvidia/pytorch:23.10-py3

RUN pip install -U pip \
    && pip install --no-cache-dir japanize_matplotlib \
    && pip install --no-cache-dir torchviz \
    && pip install --no-cache-dir torchinfo \
    && pip install --no-cache-dir mlflow \
    && pip install --no-cache-dir autopep8 \
    && pip install --no-cache-dir ipywidgets \
    && jupyter nbextension enable --py widgetsnbextension

RUN apt-get update && apt-get install -y \
    screen

RUN conda install graphviz \
    && conda clean -i -t -y

# work in container rootless.
RUN useradd -m -d /home/dev-user -s /bin/bash dev-user
USER dev-user

# save gpu session between local and container.
CMD screen watch -n 1 nvidia-smi
