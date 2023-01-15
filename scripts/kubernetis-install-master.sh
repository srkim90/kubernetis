#!/bin/bash

# 쿠버네티스 초기화 명령 실행
kubeadm init --apiserver-advertise-address 192.168.20.10 --pod-network-cidr=20.96.0.0/12
kubeadm token create --print-join-command > ~/join.sh

# 환경변수 설정
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# Kubectl 자동완성 기능 설치
yum install bash-completion -y
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc

# Calico 설치
curl https://docs.projectcalico.org/manifests/calico.yaml -O
kubectl apply -f calico.yaml

# Dashboard 설치
kubectl apply -f https://kubetm.github.io/yamls/k8s-install/dashboard-2.3.0.yaml
nohup kubectl proxy --port=8001 --address=192.168.20.10 --accept-hosts='^*$' >/dev/null 2>&1 &
