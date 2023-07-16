#!/bin/bash
echo "Creating gh-key file in ./files which will be used to ssh into the bastion host"
[-d files ] || mkdir files
ssh-keygen -t ed25519 -N "" -f ./files//gh-ke

echo "Installing aws cli tool"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

echo "Installing terraform tool"
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

echo "Please run terraform plan and then terraform apply to create the infrastructure."
