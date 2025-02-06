# Kubernetes 클러스터를 위한 VMware 기반 Vagrantfile
# Ubuntu 22.04 사용
BOX_IMAGE = "generic/ubuntu2204"
N = 2 # Worker 노드 개수

Vagrant.configure("2") do |config|
  # 공통 설정
  config.vm.box = BOX_IMAGE
  config.vm.provider "vmware_desktop" do |v|
    v.memory = 2048
    v.cpus = 2
    v.linked_clone = true
  end

  #----- Master Node 설정 -----
  config.vm.define "k8s-master" do |subconfig|
    subconfig.vm.provider "vmware_desktop" do |v|
      v.memory = 3072
      v.cpus = 2
    end
    subconfig.vm.hostname = "k8s-master"

    # VMware NAT 네트워크 사용
    subconfig.vm.network "private_network", ip: "192.168.100.100"

    # SSH 접속을 위한 포트 포워딩
    subconfig.vm.network "forwarded_port", guest: 22, host: 50010, auto_correct: true, id: "ssh"
    subconfig.vm.synced_folder "./", "/vagrant", disabled: true

    # Kubernetes 초기화 스크립트 실행
    subconfig.vm.provision "shell", path: "init_cfg.sh", args: N
    subconfig.vm.provision "shell", path: "master.sh", args: N
  end

  #----- Worker Nodes 설정 -----
  (1..N).each do |i|
    config.vm.define "k8s-worker#{i}" do |subconfig|
      subconfig.vm.provider "vmware_desktop" do |v|
        v.memory = 2048
        v.cpus = 2
      end
      subconfig.vm.hostname = "k8s-worker#{i}"

      # VMware NAT 네트워크 사용
      subconfig.vm.network "private_network", ip: "192.168.100.10#{i}"

      # SSH 접속을 위한 포트 포워딩
      subconfig.vm.network "forwarded_port", guest: 22, host: 5001 + i, auto_correct: true, id: "ssh"
      subconfig.vm.synced_folder "./", "/vagrant", disabled: true

      # Kubernetes 초기화 스크립트 실행
      subconfig.vm.provision "shell", path: "init_cfg.sh", args: N
      subconfig.vm.provision "shell", path: "worker.sh"
    end
  end
end
