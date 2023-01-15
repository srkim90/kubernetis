
# ssh password 접속 활성화
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config;
systemctl restart sshd.service

# 방화벽 해제
systemctl stop firewalld && systemctl disable firewalld
systemctl stop NetworkManager && systemctl disable NetworkManager

# Swap 비활성화
swapoff -a && sed -i '/ swap / s/^/#/' /etc/fstab

# br_netfilter 모듈 로드
cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

# Iptables 커널 옵션 활성화
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

# permissive 모드로 SELinux 설정(효과적으로 비활성화)
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# 쿠버네티스 YUM Repository 설정
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

# Centos Update
yum -y update

# Hosts 등록
cat << EOF >> /etc/hosts
192.168.56.30 k8s-master
192.168.56.31 k8s-node1
192.168.56.32 k8s-node2
EOF

# 도커 설치
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y containerd.io-1.4.9-3.1.el7 docker-ce-3:20.10.8-3.el7.x86_64 docker-ce-cli-1:20.10.8-3.el7.x86_64


mkdir /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF
mkdir -p /etc/systemd/system/docker.service.d

# 도커 재시작
systemctl daemon-reload
systemctl enable --now docker


# 쿠버네티스 설치
yum install -y kubelet-1.22.0-0.x86_64 kubeadm-1.22.0-0.x86_64 kubectl-1.22.0-0.x86_64 --disableexcludes=kubernetes
systemctl enable --now kubelet