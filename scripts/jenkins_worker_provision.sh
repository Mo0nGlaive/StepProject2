#!/bin/bash
set -e

echo "[Jenkins Worker] Installing Java and Docker engine"

sudo apt update
sudo apt install fontconfig openjdk-21-jre -y

echo "[Jenkins Worker] Java $(java -version 2>&1 | head -1) installed"

echo "[Jenkins Worker] Adding Docker's official GPG key"

sudo apt update
sudo apt install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "[Jenkins Worker] Adding the repository to Apt sources"

sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update

sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl status docker

echo "[Jenkins Worker] Docker engine installed"

echo "[Jenkins Worker] Installing SSH server"

sudo apt install openssh-server -y

sudo systemctl enable ssh
sudo systemctl start ssh

echo "[Jenkins Worker] Creating Jenkins user"

if ! id jenkins >/dev/null 2>&1; then
    sudo useradd -m -s /bin/bash jenkins
fi


sudo usermod -aG docker jenkins

echo "[Jenkins Worker] Configuring SSH"

sudo mkdir -p /home/jenkins/.ssh
sudo chmod 700 /home/jenkins/.ssh
sudo chown -R jenkins:jenkins /home/jenkins/.ssh

sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' \
    /etc/ssh/sshd_config

sudo systemctl restart ssh

echo "[Jenkins Worker] Configuring SSH access"

sudo mkdir -p /home/jenkins/.ssh
sudo chmod 700 /home/jenkins/.ssh

if [ -f /vagrant/jenkins_worker_key.pub ]; then

    sudo cp /vagrant/jenkins_worker_key.pub \
        /home/jenkins/.ssh/authorized_keys

    sudo chmod 600 /home/jenkins/.ssh/authorized_keys
    sudo chown -R jenkins:jenkins /home/jenkins/.ssh

    echo "[Jenkins Worker] Controller public key installed"

else
    echo "[Jenkins Worker] /vagrant/jenkins_worker_key.pub not found"
    echo "[Jenkins Worker] SSH key authentication is not configured"
fi
