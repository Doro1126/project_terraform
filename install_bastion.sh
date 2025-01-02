#!/bin/bash
sudo apt update -y
sudo apt install -y git curl wget mysql-client
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
git clone https://github.com/Doro1126/mywebhook.git
git clone https://github.com/Doro1126/lab.git
cd mywebhook
npm install
sudo systemctl disable ufw --now