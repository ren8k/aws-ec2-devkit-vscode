#!/bin/bash

# check cuda
echo "==============check cuda=============="
nvcc -V

# check gpu
echo "==============check gpu=============="
nvidia-smi

# check torch
echo "==============check torch=============="
echo "if you exec at first time, you might wait for a while..."
python -c "import torch; print(f'torch.__version__: {torch.__version__}')"
python -c "import torch; print(f'torch.cuda.is_available(): {torch.cuda.is_available()}')"
