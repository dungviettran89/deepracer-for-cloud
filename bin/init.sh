#!/usr/bin/env bash
GPUS=$(docker run --gpus all nvidia/cuda:10.2-base nvidia-smi "-L" | awk  '/GPU .:/' | wc -l)
if [ $? -ne 0 ] || [ $GPUS -eq 0 ]
then
	echo "No GPU detected in docker. Please check setup".
	exit 1
fi

INSTALL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null 2>&1 && pwd )"
cd $INSTALL_DIR

# create directory structure for docker volumes
mount /mnt
sudo mkdir -p /mnt/deepracer /mnt/deepracer/recording /mnt/deepracer/robo/checkpoint 
sudo chown -R $(id -u):$(id -g) /mnt/deepracer 
mkdir -p $INSTALL_DIR/docker/volumes

# create symlink to current user's home .aws directory 
# NOTE: AWS cli must be installed for this to work
# https://docs.aws.amazon.com/cli/latest/userguide/install-linux-al2017.html
ln -s $(eval echo "~${USER}")/.aws  $INSTALL_DIR/docker/volumes/

# grab local training deepracer repo from crr0004 and log analysis repo from vreadcentric
# Now as submodules!
# git clone --recurse-submodules https://github.com/crr0004/deepracer.git
# git clone https://github.com/breadcentric/aws-deepracer-workshops.git && cd aws-deepracer-workshops && git checkout enhance-log-analysis && cd ..
git submodule update --init --recursive

ln -sf $INSTALL_DIR/aws-deepracer-workshops/log-analysis  $INSTALL_DIR/docker/volumes/log-analysis
cp $INSTALL_DIR/deepracer/simulation/aws-robomaker-sample-application-deepracer/simulation_ws/src/deepracer_simulation/routes/* docker/volumes/log-analysis/tracks/

# copy rewardfunctions
mkdir -p $INSTALL_DIR/custom_files $INSTALL_DIR/analysis
cp $INSTALL_DIR/deepracer/custom_files/* $INSTALL_DIR/custom_files/
cp $INSTALL_DIR/defaults/hyperparameters.json $INSTALL_DIR/custom_files/

# setup symlink to rl-coach config file
ln -f $INSTALL_DIR/defaults/rl_deepracer_coach_robomaker.py $INSTALL_DIR/deepracer/rl_coach/rl_deepracer_coach_robomaker.py 
cd $INSTALL_DIR/deepracer/ && patch simulation/aws-robomaker-sample-application-deepracer/simulation_ws/src/sagemaker_rl_agent/markov/environments/deepracer_racetrack_env.py < ../defaults/deepracer_racetrack_env.py.patch && cd ..

# replace the contents of the rl_deepracer_coach_robomaker.py file with the gpu specific version (this is also where you can edit the hyperparameters)
# TODO this file should be genrated from a gui before running training
cp $INSTALL_DIR/defaults/template-run.env $INSTALL_DIR/current-run.env

#set proxys if required
for arg in "$@";
do
    IFS='=' read -ra part <<< "$arg"
    if [ "${part[0]}" == "--http_proxy" ] || [ "${part[0]}" == "--https_proxy" ] || [ "${part[0]}" == "--no_proxy" ]; then
        var=${part[0]:2}=${part[1]}
        args="${args} --build-arg ${var}"
    fi
done

# Download docker images. Change to build statements if locally built images are desired.
# docker build ${args} -f ./docker/dockerfiles/rl_coach/Dockerfile -t larsll/deepracer-rlcoach ./
# docker build ./docker/dockerfiles/deepracer_robomaker/ -t larsll/deepracer-robomaker
# docker build ./docker/dockerfiles/log-analysis/ -t larsll/deepracer-loganalysis
docker pull larsll/deepracer-rlcoach
docker pull larsll/deepracer-robomaker
# docker pull larsll/deepracer-loganalysis
docker pull crr0004/sagemaker-rl-tensorflow:nvidia

# create the network sagemaker-local if it doesn't exit
SAGEMAKER_NW='sagemaker-local'
docker network ls | grep -q $SAGEMAKER_NW
if [ $? -ne 0 ]
then
	  docker network create $SAGEMAKER_NW
fi