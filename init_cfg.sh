#!/usr/bin/env bash

# config sshd
echo ">>>> ssh-config <<<<<<"
sed -i "s/^PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sed -i "s/^#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /etc/ssh/sshd_config
systemctl restart sshd

# profile bashrc settting
echo 'alias vi=vim' >> /etc/profile
echo "sudo su -" >> .bashrc

# Letting iptables see bridged traffic
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

# local dns setting
echo "192.168.100.100 k8s-master" >> /etc/hosts
for (( i=1; i<=$1; i++  )); do echo "192.168.100.10$i k8s-w$i" >> /etc/hosts; done

# apparmor disable
systemctl stop apparmor && systemctl disable apparmor

# remove ufw
systemctl disable --now ufw
apt remove -y ufw

# package install
apt update
apt-get install git vim wget zsh bridge-utils net-tools jq tree resolvconf wireguard -y

# config dnsserver ip
echo -e "nameserver 8.8.8.8\nnameserver 168.126.63.1" > /etc/resolvconf/resolv.conf.d/head
resolvconf -u

# docker install
curl -fsSL https://get.docker.com | sh

# Cgroup Driver systemd
cat <<EOF | tee /etc/docker/daemon.json
{"exec-opts": ["native.cgroupdriver=systemd"]}
EOF
systemctl daemon-reload && systemctl restart docker

## containerd 재설치
apt-get update && apt-get install -y containerd
mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sed -i "s/^SystemdCgroup = false/SystemdCgroup = true/g" /etc/containerd/config.toml
systemctl restart containerd

# swap off
swapoff -a

# Installing kubeadm kubelet and kubectl
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl

# 최신 버전
#sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg
#echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# 지정 버전
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet && systemctl start kubelet

apt-get upgrade -y && apt-get autoremove -y