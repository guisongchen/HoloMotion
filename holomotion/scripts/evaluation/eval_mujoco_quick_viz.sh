#!/bin/bash
source train.env

export CUDA_VISIBLE_DEVICES=""

# 使用 GLFW 进行可视化（带窗口）
export MUJOCO_GL="glfw"
export RECORD_VIDEO=false

robot_xml_path="assets/robots/unitree/G1/29dof/scene_29dof.xml"

# 使用快速验证导出的 ONNX 模型
ONNX_PATH="logs/HoloMotionMotionTrackingQuick/20260307_200611-quick_validation/exported/model_999.onnx"

# 选择一个简单的站立动作进行可视化
export motion_npz_path="data/holomotion_retargeted/processed_datasets/AMASS_ACCAD/clips/ACCAD_Female1General_c3d_A1_-_Stand_stageii.npz"

echo "=========================================="
echo "MuJoCo Visualization"
echo "=========================================="
echo "ONNX: $ONNX_PATH"
echo "Motion: $motion_npz_path"
echo "=========================================="

${Train_CONDA_PREFIX}/bin/python holomotion/src/evaluation/eval_mujoco_sim2sim.py \
    +ckpt_onnx_path="$ONNX_PATH" \
    record_video=$RECORD_VIDEO \
    headless=false \
    camera_tracking=true \
    camera_distance=4.0 \
    camera_azimuth=60 \
    camera_elevation=-20 \
    +motion_npz_path='${oc.env:motion_npz_path}' \
    +robot_xml_path=${robot_xml_path}
