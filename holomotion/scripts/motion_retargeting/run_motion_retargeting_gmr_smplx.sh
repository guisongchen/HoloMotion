source train.env

smplx_src_dir="data/amass_compatible_datasets/amass/"
gmr_tgt_dir="data/gmr_retargeted/AMASS_ACCAD/"


# create gmr_tgt_dir if not exists
if [ ! -d "$gmr_tgt_dir" ]; then
    mkdir -p $gmr_tgt_dir
fi

$Train_CONDA_PREFIX/bin/python \
    thirdparties/GMR/scripts/smplx_to_robot_dataset.py \
    --src_folder=${smplx_src_dir}/ \
    --tgt_folder=${gmr_tgt_dir}/ \
    --num_cpus=8 \
    --robot=unitree_g1



