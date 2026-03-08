#!/bin/bash
source train.env
export CUDA_VISIBLE_DEVICES="0"

CONFIG_NAME="eval_isaaclab"
# 使用最新训练的检查点（训练完成后更新此路径）
CKPT_PATH="logs/HoloMotionMotionTracking/20260307_194639-train_g1_29dof_motion_tracking_AMASS_ACCAD/model_0.pt"
eval_h5_dataset_path="data/hdf5_datasets/processed_datasets/h5_AMASS_ACCAD"
num_envs=1

${Train_CONDA_PREFIX}/bin/accelerate launch \
    holomotion/src/evaluation/eval_motion_tracking_single.py \
    --config-name=evaluation/${CONFIG_NAME} \
    checkpoint=$CKPT_PATH \
    headless=false \
    project_name="HoloMotionMotionTracking" \
    num_envs=${num_envs} \
    export_policy=true \
    dump_npzs=true \
    motion_h5_path=${eval_h5_dataset_path}
