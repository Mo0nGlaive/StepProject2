#!/bin/bash
set -e

echo "[Jenkins] Installing Jenkins and Docker engine"

sudo apt update
sudo apt install fontconfig openjdk-21-jre -y

echo "[Jenkins] Java $(java -version 2>&1 | head -1) installed"

sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian/jenkins.io-2026.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install jenkins -y

sudo systemctl status jenkins

echo "[Jenkins] Jenkins installed"

echo "[Jenkins] Adding Docker's official GPG key"

sudo apt update
sudo apt install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "[Jenkins] Adding the repository to Apt sources"

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

echo "[Jenkins] Docker engine installed"

echo "[Jenkins] Creating Jenkins user"

if ! id jenkins >/dev/null 2>&1; then
    sudo useradd -m -s /bin/bash jenkins
fi

sudo usermod -aG docker jenkins

echo "[Jenkins] Generating SSH key for Jenkins Worker"

if [ ! -f /vagrant/jenkins_worker_key ]; then

    sudo -u jenkins ssh-keygen -t ed25519 -N "" -f /vagrant/jenkins_worker_key

    sudo chown jenkins:jenkins /vagrant/jenkins_worker_key
    sudo chown jenkins:jenkins /vagrant/jenkins_worker_key.pub

fi

echo "[Jenkins] SSH key generated"

echo "[Jenkins] DONE"