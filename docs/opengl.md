# GPU Accelerated OpenGL for Robomaker

One way to improve performance, especially of Robomaker, is to enable GPU-accelerated OpenGL. OpenGL can significantly improve Gazebo performance, even where the GPU does not have enough GPU RAM, or is too old, to support Tensorflow.

## Desktop 

On a Ubuntu desktop running Unity there are hardly any additional steps required.

* Ensure that a recent Nvidia driver is installed and is running.
* Ensure that nvidia-docker is installed; review `bin/prepare.sh` for steps if you do not want to directly run the script.
* Configure DRfC using the following settings in `system.env`:
    * `DR_HOST_X=True`; uses the local X server rather than starting one within the docker container.
    * `DR_ROBOMAKER_IMAGE`; choose the tag for an OpenGL enabled image - e.g. `cpu-gl-avx` for an image where Tensorflow will use CPU or `gpu-gl` for an image where also Tensorflow will use the GPU.

Before running `dr-start-training` ensure that environment variables `DISPLAY` and `XAUTHORITY` are defined.

With recent Nvidia drivers you can confirm that the setup is working by running `nvidia-smi` on the host and see that `gzserver` is listed as running on the GPU. Older drivers (e.g. 390 for NVS 315) may not support showing which processes are running on the GPU.

## Headless Server

Also a headless server with a GPU, e.g. an EC2 instance, or a local computer with a displayless GPU (e.g. Tesla K40, K80, M40).

* Ensure that a Nvidia driver and nvidia-docker is installed; review `bin/prepare.sh` for steps if you do not want to directly run the script.
* Setup an X-server on the host. `utils\setup-xorg.sh` is a basic installation script.
* Configure DRfC using the following settings in `system.env`:
    * `DR_HOST_X=True`; uses the local X server rather than starting one within the docker container.
    * `DR_ROBOMAKER_IMAGE`; choose the tag for an OpenGL enabled image - e.g. `cpu-gl-avx` for an image where Tensorflow will use CPU or `gpu-gl` for an image where also Tensorflow will use the GPU.

Before training ensure that the server is running, including VNC if you want to connect. Ensure that environment variables `DISPLAY` and `XAUTHORITY` are defined.

Basic start-up including creation of variables can be achieved with `source utils\start-xorg.sh`.

With recent Nvidia drivers you can confirm that the setup is working by running `nvidia-smi` on the host and see that `gzserver` is listed as running on the GPU.
