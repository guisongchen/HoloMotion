#!/bin/bash
source train.env

export CUDA_VISIBLE_DEVICES=0

config_name="train_g1_29dof_motion_tracking_quick"
num_envs=512

COMMON_ARGS=(
    "holomotion/src/training/train.py"
    "--config-name=training/motion_tracking/${config_name}"
    "num_envs=${num_envs}"
    "headless=true"
    "experiment_name=quick_validation"
)

trap cleanup SIGINT SIGTERM
${Train_CONDA_PREFIX}/bin/accelerate launch \
    "${COMMON_ARGS[@]}"
wait ${TRAIN_PID}
trap - SIGINT SIGTERM
