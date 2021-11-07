
# install-kubernetes.sh

sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update

# install kubelet kubeadm kubectl 1.19.15
sudo apt-get install -y kubelet=1.19.15-00 kubeadm=1.19.15-00 kubectl=1.19.15-00
# hold the .
sudo apt-mark hold kubelet kubeadm kubectl
# check kubernetes version
kubeadm version
kubelet --version
kubectl version

# kubeadm init
sudo kubeadm init --apiserver-advertise-address 192.168.35.10 --pod-network-cidr=192.168.0.0/24

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config
