#!/bin/bash
sudo apt update -y
sudo apt install -y git curl wget 
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
git clone https://github.com/kimcity0205/nodejs_Pro.git
cd myweb
npm install
sudo systemctl disable ufw --now
