#!/bin/bash
# Move to Desktop
cd ~/Desktop

# Activate conda environment
eval "$(/Users/yuvalsavaryegolandesman/miniconda3/bin/conda shell.bash hook)" 
conda activate ai

# Run uvicorn
uvicorn Image_to_Label_TFLite:app --host 0.0.0.0 --port 8000
