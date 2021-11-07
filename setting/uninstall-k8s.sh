# unhold the kubelet kubeadm kubectl
sudo apt-mark unhold kubelet kubeadm kubectl;
sudo kubeadm reset;
sudo apt-get purge kubeadm kubectl kubelet kubernetes-cni kube*;
sudo apt-get autoremove -y;

sudo rm -rf ~/.kube
