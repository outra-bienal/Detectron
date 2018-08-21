# Adaptation from: https://gist.github.com/matsui528/6d223d17241842c84d5882a9afa0453a
#
#
#
# Install script of Caffe2 and Detectron on AWS EC2
#
# Tested environment:
#   - AMI: Deep Learning Base AMI (Ubuntu) Version 6.0 - ami-ce3673b6  (CUDA is already installed)
#   - Instance: p3.2xlarge (V100 * 1)
#   - Caffe2: https://github.com/pytorch/pytorch/commit/731273b8d61dfa2aa8b2909f27c8810ede103952
#   - Detectron: https://github.com/facebookresearch/Detectron/commit/cd447c77c96f5752d6b37761d30bbdacc86989a2
#
# Usage:
#   Launch a fresh EC2 instance, put this script on the /home/ubuntu/, and run the following command.
#   $ cd ~
#   $ source install_caffe2_detectron.sh
#
# Test:
#   $ cd ~/work/detectron/detectron
#   $ python2 tests/test_spatial_narrow_as_op.py
#
# Run samples:
#   Run the following commands and see the results in /tmp/detectron-visualizations
#   $ cd ~/work/detectron
#   $ python2 tools/infer_simple.py \
#    --cfg configs/12_2017_baselines/e2e_mask_rcnn_R-101-FPN_2x.yaml \
#    --output-dir /tmp/detectron-visualizations \
#    --image-ext jpg \
#    --wts https://s3-us-west-2.amazonaws.com/detectron/35861858/12_2017_baselines/e2e_mask_rcnn_R-101-FPN_2x.yaml.02_32_51.SgT4y1cO/output/train/coco_2014_train:coco_2014_valminusminival/generalized_rcnn/model_final.pkl \
#    demo
#
# Note that:
#   - In the Deep Learning AMI (Version 4.0), CUDA and caffe2 are already installed. But the caffe2 in the AMI is
#     a bit old version and does not include some modules required for Detectron.
#     So this script supposes that an AMI is Deep Learning "Base" AMI (Version 6.0), where only CUDA is installed.
#   - Manual configuration of setup.py is not a recommended way. Any suggestions are welcome.



INSTALL_DIR=~/work

### Install Caffe2
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
      build-essential \
      cmake \
      git \
      libgoogle-glog-dev \
      libgtest-dev \
      libiomp-dev \
      libleveldb-dev \
      liblmdb-dev \
      libopencv-dev \
      libopenmpi-dev \
      libsnappy-dev \
      libprotobuf-dev \
      openmpi-bin \
      openmpi-doc \
      protobuf-compiler \
      python-dev \
      python-pip
sudo pip2 install \
      future \
      numpy \
      protobuf
sudo apt-get install -y --no-install-recommends libgflags-dev

mkdir -p $INSTALL_DIR && cd $INSTALL_DIR
git clone --recursive https://github.com/pytorch/pytorch.git && cd pytorch
git submodule update --init
mkdir -p build && cd build
cmake ..
sudo make install -j6

# Export paths
echo "export PYTHONPATH=/usr/local:\$PYTHONPATH" >> ~/.bashrc
echo "export PYTHONPATH=\$PYTHONPATH:${INSTALL_DIR}/caffe2/build" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=/usr/local/lib:\$LD_LIBRARY_PATH" >> ~/.bashrc
source ~/.bashrc


### Install Detectron
sudo pip2 install numpy pyyaml matplotlib opencv-python setuptools cython mock scipy

# First, install coco api
COCOAPI=$INSTALL_DIR/cocoapi
git clone https://github.com/cocodataset/cocoapi.git $COCOAPI
cd $COCOAPI/PythonAPI

# https://github.com/facebookresearch/Detectron/issues/105
# https://github.com/cocodataset/cocoapi/issues/94
# Based on the comments above, insert `extra_link_args=['-L/usr/lib/x86_64-linux-gnu/']` in setup.py
sed -i -e "/extra_compile_args/a \        extra_link_args=['-L/usr/lib/x86_64-linux-gnu/']," setup.py

# Install into global site-packages
sudo make install

# Next, install detectron
DETECTRON=$INSTALL_DIR/detectron
git clone https://github.com/outra-bienal/detectron $DETECTRON
cd $DETECTRON
make
