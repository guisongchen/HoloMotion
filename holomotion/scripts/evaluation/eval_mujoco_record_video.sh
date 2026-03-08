#!/bin/bash
source train.env

export CUDA_VISIBLE_DEVICES=""

# 使用 OSMesa 进行离屏渲染并录制视频
export MUJOCO_GL="osmesa"
export RECORD_VIDEO=true

robot_xml_path="assets/robots/unitree/G1/29dof/scene_29dof.xml"
ONNX_PATH="logs/HoloMotionMotionTrackingQuick/20260307_200611-quick_validation/exported/model_999.onnx"
export motion_npz_path="data/holomotion_retargeted/processed_datasets/AMASS_ACCAD/clips/ACCAD_Female1General_c3d_A1_-_Stand_stageii.npz"

${Train_CONDA_PREFIX}/bin/python holomotion/src/evaluation/eval_mujoco_sim2sim.py \
    +ckpt_onnx_path="$ONNX_PATH" \
    record_video=$RECORD_VIDEO \
    headless=true \
    camera_tracking=true \
    camera_distance=4.0 \
    +motion_npz_path='${oc.env:motion_npz_path}' \
    +robot_xml_path=${robot_xml_path}

# 查找生成的视频文件
echo "=========================================="
echo "Video files generated:"
find . -name "*.mp4" -type f -mmin -5 2>/dev/null
