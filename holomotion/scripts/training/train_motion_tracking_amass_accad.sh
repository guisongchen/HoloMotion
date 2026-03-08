# Project HoloMotion
source train.env

export CUDA_VISIBLE_DEVICES=0

config_name="train_g1_29dof_motion_tracking"
num_envs=2048

COMMON_ARGS=(
    "holomotion/src/training/train.py"
    "--config-name=training/motion_tracking/${config_name}"
    "num_envs=${num_envs}"
    "headless=true"
    "experiment_name=${config_name}_AMASS_ACCAD"
)

trap cleanup SIGINT SIGTERM
${Train_CONDA_PREFIX}/bin/accelerate launch \
    "${COMMON_ARGS[@]}"
wait ${TRAIN_PID}
trap - SIGINT SIGTERM
