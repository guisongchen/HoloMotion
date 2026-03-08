#!/bin/bash
source train.env
export CUDA_VISIBLE_DEVICES="0"

CONFIG_NAME="eval_isaaclab"
# 使用快速验证训练的检查点
CKPT_PATH="logs/HoloMotionMotionTrackingQuick/20260307_200611-quick_validation/model_999.pt"
eval_h5_dataset_path="data/hdf5_datasets/processed_datasets/h5_AMASS_ACCAD"
num_envs=1

${Train_CONDA_PREFIX}/bin/accelerate launch \
    holomotion/src/evaluation/eval_motion_tracking_single.py \
    --config-name=evaluation/${CONFIG_NAME} \
    checkpoint=$CKPT_PATH \
    headless=false \
    project_name="HoloMotionMotionTrackingQuick" \
    num_envs=${num_envs} \
    export_policy=true \
    dump_npzs=true \
    motion_h5_path=${eval_h5_dataset_path}
