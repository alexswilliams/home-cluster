#!/usr/bin/env bash

echo Provisioning Kube Admin
set -ex

DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND

sudo timedatectl set-timezone Etc/UTC

echo Clearing previous installation
sudo kubeadm reset -f || true
sudo apt-get -y purge kubelet kubectl kubeadm --allow-change-held-packages
sudo apt-get -y purge docker docker-engine docker.io containerd runc --allow-change-held-packages
sudo apt-get -y autoremove
rm -rf ~/.kube
sudo rm -rf /etc/kubernetes
sudo rm -rf /var/lib/docker


echo Setting up Docker
sudo apt-get update && sudo apt-get install -y apt-transport-https curl ca-certificates software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo add-apt-repository -y "deb http://apt.kubernetes.io/ kubernetes-xenial main"
sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get -y dist-upgrade
sudo apt-get install docker-ce

echo """
{
  "insecure-registries":["docker-registry-service:5000"],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
""" | sudo tee /etc/docker/daemon.json

echo Installing kubeadm, kubelet and kubectl
sudo apt-get -y install kubelet=1.15.1-00 kubectl=1.15.1-00 kubeadm=1.15.1-00
sudo apt-mark hold kubelet

sudo kubeadm init --apiserver-cert-extra-sans london.alexswilliams.co.uk --ignore-preflight-errors=NumCPU
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl version
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

# kubeadm completion bash > ~/.kube/kubeadm_completion.bash.inc
# cat >>$HOME/.bash_profile <<EOF
# # Kubeadm shell completion\
# source '$HOME/.kube/kubeadm_completion.bash.inc'
# EOF

# kubectl completion bash > ~/.kube/completion.bash.inc
# cat >>$HOME/.bash_profile <<EOF
# # Kubectl shell completion
# source '$HOME/.kube/completion.bash.inc'
# EOF

source $HOME/.bash_profile

kubectl taint nodes --all node-role.kubernetes.io/master:NoSchedule-
