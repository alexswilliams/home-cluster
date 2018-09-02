$kubeadmin_setup = <<-SCRIPT
echo Provisioning Kube Admin
set -ex

sudo timedatectl set-timezone Etc/UTC

# k8s initialisation

# DEBIAN_FRONTEND=noninteractive sudo apt-get update && sudo apt-get install -y apt-transport-https curl ca-certificates software-properties-common
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
# curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
# sudo add-apt-repository -y "deb http://apt.kubernetes.io/ kubernetes-xenial main"
# sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
# DEBIAN_FRONTEND=noninteractive sudo apt-get update
# DEBIAN_FRONTEND=noninteractive sudo apt-get -y dist-upgrade

# sudo kubeadm reset || true
# DEBIAN_FRONTEND=noninteractive sudo apt-get -y purge kubelet kubectl kubeadm
# rm -rf ~/.kube

# DEBIAN_FRONTEND=noninteractive sudo apt-get -y install kubelet=1.10.6-00 kubectl=1.10.6-00 kubeadm=1.10.6-00 docker-ce
# DEBIAN_FRONTEND=noninteractive sudo apt-mark hold kubelet kubeadm kubectl

sudo kubeadm init --apiserver-cert-extra-sans london.alexswilliams.co.uk
rm -rf $HOME/.kube
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl version
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

kubeadm completion bash > ~/.kube/kubeadm_completion.bash.inc
printf "
  # Kubeadm shell completion\
  source '$HOME/.kube/kubeadm_completion.bash.inc'
" >> $HOME/.bash_profile
kubectl completion bash > ~/.kube/completion.bash.inc
printf "
  # Kubectl shell completion
  source '$HOME/.kube/completion.bash.inc'
" >> $HOME/.bash_profile
source $HOME/.bash_profile

kubectl taint nodes --all node-role.kubernetes.io/master:NoSchedule-

SCRIPT


Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"
  config.vm.box_version = "20180809.0.0"

  config.vm.define "kube-admin" do |m|
    m.vm.hostname = "kube-admin.vagrant.local"
    m.vm.network :private_network, ip: "192.168.88.10"
    m.vm.provider :virtualbox do |vb|
      vb.name = "kube-admin"
      vb.cpus = 1
      vb.memory = 1024
    end
    m.vm.provision :ansible do |ansible|
      ansible.verbose = "v"
      ansible.playbook = "ansible-config/kube-admin.yml"
    end
    m.vm.provision :shell, inline: $kubeadmin_setup
  end

  # config.vm.define "kube-node-1" do |m|
  #   m.vm.hostname = "kube-node-1.vagrant.local"
  #   m.vm.network :private_network, ip: "192.168.88.20"
  #   m.vm.provider :virtualbox do |vb|
  #     vb.name = "kube-node-1"
  #     vb.cpus = 2
  #     vb.memory = 2048
  #   end
  # end

  #  config.vm.synced_folder ".", "/vagrant", disabled: true
end
