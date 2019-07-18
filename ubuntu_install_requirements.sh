#!/usr/bin/env bash
set -ex

source lib/logging.sh

# sudo apt install -y libselinux-utils
# if selinuxenabled ; then
#     sudo setenforce permissive
#     sudo sed -i "s/=enforcing/=permissive/g" /etc/selinux/config
# fi

# Update to latest packages first
sudo apt -y update

# Install EPEL required by some packages
# if [ ! -f /etc/yum.repos.d/epel.repo ] ; then
#     if grep -q "Red Hat Enterprise Linux" /etc/redhat-release ; then
#         sudo yum -y install http://mirror.centos.org/centos/7/extras/x86_64/Packages/epel-release-7-11.noarch.rpm
#     else
#         sudo yum -y install epel-release --enablerepo=extras
#     fi
# fi

# Work around a conflict with a newer zeromq from epel
# if ! grep -q zeromq /etc/yum.repos.d/epel.repo; then
#   sudo sed -i '/enabled=1/a exclude=zeromq*' /etc/yum.repos.d/epel.repo
# fi

# Install required packages
# python-{requests,setuptools} required for tripleo-repos install
sudo apt -y install \
  net-tools \
  crudini \
  curl \
  dnsmasq \
  figlet \
  nmap \
  patch \
  psmisc \
  python-pip \
  python-netaddr \
  python-requests \
  python-setuptools \
  python-libvirt \
  wget

# Check if 'ifconfig' is available!
if [[ ! $(ifconfig) ]]; then
  echo "Cannot run ifconfig..."
  echo "Install net-tools package"
  sudo apt -y install net-tools
fi

# We're reusing some tripleo pieces for this setup so clone them here

## We don't need TripleO repos in Ubuntu
##cd
##if [ ! -d tripleo-repos ]; then
##  git clone https://git.openstack.org/openstack/tripleo-repos
##fi
##pushd tripleo-repos
##sudo python setup.py install
##popd

# Needed to get a recent python-virtualbmc package
#sudo tripleo-repos current-tripleo

# There are some packages which are newer in the tripleo repos

# Setup yarn and nodejs repositories
#sudo curl -sL https://dl.yarnpkg.com/rpm/yarn.repo -o /etc/yum.repos.d/yarn.repo
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
#curl -sL https://rpm.nodesource.com/setup_10.x | sudo bash -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

# Add this repository to install podman
sudo add-apt-repository -y ppa:projectatomic/ppa

# Update some packages from new repos
sudo apt -y update

# make sure additional requirments are installed

# Setup Golang 1.12
sudo add-apt-repository ppa:longsleep/golang-backports
sudo apt-get update
sudo apt-get install -y golang-go

# mkdir /tmp/dsi309gdkh7 -p
# curl -O  https://dl.google.com/go/go1.12.7.linux-amd64.tar.gz -o /tmp/dsi309gdkh7/golang.tar.gz
# tar -xvf /tmp/dsi309gdkh7/golang.tar.gz
# mv go /usr/local/bin/
# rm /tmp/dsi309gdkh7
# if [[  $PATH != *go* ]]; then
#   export PATH=$PATH:/usr/local/bin/go/bin
# fi


##No bind-utils. It is for host, nslookop,..., no need in ubuntu
sudo apt -y install \
  jq \
  libguestfs-tools \
  nodejs \
  podman \
  qemu-kvm \
  libvirt-bin libvirt-clients libvirt-dev \
  python-ironicclient \
  python-ironic-inspector-client \
  python-lxml \
  unzip \
  yarn \
  genisoimage

# Install python packages not included as rpms
sudo pip install \
  ansible==2.8.2 \
  lolcat \
  yq \
  virtualbmc \


if ! which minikube 2>/dev/null ; then
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
          && chmod +x minikube && sudo mv minikube /usr/local/bin/.
fi

if ! which docker-machine-driver-kvm2 >/dev/null ; then
    curl -LO https://storage.googleapis.com/minikube/releases/latest/docker-machine-driver-kvm2 \
          && sudo install docker-machine-driver-kvm2 /usr/local/bin/
fi

if ! which kubectl 2>/dev/null ; then
    curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
        && chmod +x kubectl && sudo mv kubectl /usr/local/bin/.
fi

if ! which kustomize 2>/dev/null ; then
    curl -Lo kustomize https://github.com/kubernetes-sigs/kustomize/releases/download/v2.0.3/kustomize_2.0.3_linux_amd64 \
          && chmod +x kustomize && sudo mv kustomize /usr/local/bin/.
fi
