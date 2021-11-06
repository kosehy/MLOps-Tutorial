# kubeadm init
sudo kubeadm init --apiserver-advertise-address 192.168.35.10 --pod-network-cidr=192.168.0.0/24

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config

# install calico
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
# taint node
kubectl taint nodes --all node-role.kubernetes.io/master-

# install nvidia-device-plugin
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 \
   && chmod 700 get_helm.sh \
   && ./get_helm.sh

helm repo add nvdp https://nvidia.github.io/k8s-device-plugin \
   && helm repo update

helm install --generate-name nvdp/nvidia-device-plugin

# see what changes would be made, returns nonzero returncode if different
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl diff -f - -n kube-system

# install metallb 0.11.0
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.11.0/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.11.0/manifests/metallb.yaml

# setup the metallb configmap
kubectl apply -f values_override_10.yaml

# install openebs 2.11.0
# install openEBS using kubectl
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml

# install verification
kubectl get pods -n openebs -l openebs.io/component-name=openebs-localpv-provisioner
# sleep 1 minute
sleep 90s
# change default storage class as openebs-hostpath
kubectl patch storageclass openebs-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'


sudo apt install nfs-common -y &&

# install openebs-rwx
kubectl apply -f https://openebs.github.io/charts/nfs-operator.yaml &&

# install kubernetes-dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.4.0/aio/deploy/recommended.yaml &&

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF
kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"
# edit type as LoadBalancer
KUBE_EDITOR=nano kubectl edit service -n kubernetes-dashboard kubernetes-dashboard
sudo nano kubeconfig.config
