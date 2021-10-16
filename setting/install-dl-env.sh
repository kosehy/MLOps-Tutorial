# install-dl-env.sh
#!/bin/sh

# Add additional repositories
add-apt-repository ppa:graphics-drivers/ppa -y

# Get the latest package lists
apt-get update

# Install packages
apt-get install net-tools ubuntu-drivers-common nvidia-driver-450-server nvidia-cuda-toolkit -y

# Get the latest package lists
apt-get update

apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common -y

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

apt-key fingerprint 0EBFCD88

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable" -y

# Get the latest package lists
apt-get update

# Install helm3
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 \
   && chmod 700 get_helm.sh \
   && ./get_helm.sh

# install docker-ce, docker-ce-cli containerd.io
apt-get install docker-ce docker-ce-cli containerd.io -y

# Add the package repositories
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# install nvidia-docker & nvidia-container-toolkit & openssh-client
apt-get update
apt-get install nvidia-docker2 -y

# restart the docker
systemctl restart docker

# reboot the server
reboot
