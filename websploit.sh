#!/usr/bin/env bash

# WebSploit installation script
# Author: Omar Ωr Santos
# Web: https://websploit.org
# Twitter: @santosomar
# Version: 3.4

set -x
set -e

#clear
echo "

██╗    ██╗███████╗██████╗ ███████╗██████╗ ██╗      ██████╗ ██╗████████╗
██║    ██║██╔════╝██╔══██╗██╔════╝██╔══██╗██║     ██╔═══██╗██║╚══██╔══╝
██║ █╗ ██║█████╗  ██████╔╝███████╗██████╔╝██║     ██║   ██║██║   ██║
██║███╗██║██╔══╝  ██╔══██╗╚════██║██╔═══╝ ██║     ██║   ██║██║   ██║
╚███╔███╔╝███████╗██████╔╝███████║██║     ███████╗╚██████╔╝██║   ██║
 ╚══╝╚══╝ ╚══════╝╚═════╝ ╚══════╝╚═╝     ╚══════╝ ╚═════╝ ╚═╝   ╚═╝
L A B S      B Y     O M A R   S A N T O S 

https://websploit.org
Author: Omar Ωr Santos
Twitter: @santosomar
Version: 3.2

A collection of tools, tutorials, resources, and intentionally vulnerable 
applications running in Docker containers. WebSploit Labs include 
over 500 exercises to learn and practice ethical hacking (penetration testing) skills.
--------------------------------------------------------------------------------------
"


#read -n 1 -s -r -p "Press any key to continue the setup..."

echo " "
# Setting Up vim with Python Jedi to be used in several training courses

cd /provision
apt update
apt install -y wget vim vim-python-jedi curl exuberant-ctags git ack-grep python3-pip
pip3 install pep8 flake8 pyflakes isort yapf Flask

# HACK cmm - We already have docker installed
#curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
#echo 'deb [arch=amd64] https://download.docker.com/linux/debian buster stable' | sudo tee /etc/apt/sources.list.d/docker.list
#apt update
#apt remove -P -y docker docker-engine docker.io
#apt install -y docker-ce


#echo "Installing Updating Docker-Compose!"
#sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
#sudo chmod +x /usr/local/bin/docker-compose
#
echo "getting docker-compose.yml from WebSploit.org"
wget https://websploit.org/docker-compose.yml
#
#
# instantiating the containers with docker-compose
echo "Setting up the containers and internal bridge network"
docker compose -f docker-compose.yml up -d

# Cloning the GitHub repos
mkdir -vp /root/websploit
cd /root/websploit

# cloning H4cker github
git clone https://github.com/The-Art-of-Hacking/h4cker.git

#cloning SecLists
git clone https://github.com/danielmiessler/SecLists.git

#cloning GitTools
git clone https://github.com/internetwache/GitTools.git

#cloning Payloads All The Things - A list of useful payloads and bypasses for Web Application Security. 
git clone https://github.com/swisskyrepo/PayloadsAllTheThings.git

# Getting IoTGoat and other IoT firmware for different exercises
cd /root
mkdir iot_exercises
cd iot_exercises
wget https://github.com/OWASP/IoTGoat/releases/download/v1.0/IoTGoat-raspberry-pi2.img
mv IoTGoat-raspberry-pi2.img firmware1.img

wget https://github.com/santosomar/DVRF/releases/download/v3/DVRF_v03.bin
mv DVRF_v03.bin firmware2.bin

# installing hostapd
apt install hostapd

#getting test ssl script
#curl -L https://testssl.sh --output testssl.sh
#chmod +x testssl.sh

#Installing ffuf 
apt install -y ffuf

#Installing tor
apt install -y tor

#Installing certspy
pip3 install certspy

#Installing Jupyter Notebooks
apt install -y jupyter-notebook

#Installing radamnsa
cd /root/websploit
git clone https://gitlab.com/akihe/radamsa.git && cd radamsa && make && sudo make install

#Installing EDB
apt install -y edb-debugger

#Installing gobuster
apt install -y gobuster

#Installing Sublist3r
cd /root/websploit
git clone https://github.com/aboul3la/Sublist3r.git
cd Sublist3r
pip3 install -r requirements.txt

# installing enum4linux-ng
cd /root/websploit
git clone https://github.com/cddmp/enum4linux-ng && cd enum4linux-ng


#Installing searchsploit in Parrot
# Parrot does not come with searchsploit. This will install it if the user opts to use Parrot vs Kali.

distribution=$(lsb_release -i | awk '{print $(NF)}')
if [[ "$distribution" == "Parrot" ]];
then
  git clone https://github.com/offensive-security/exploitdb.git /opt/exploitdb
  ln -sf /opt/exploitdb/searchsploit /usr/local/bin/searchsploit
fi

# Installing NodeGoat
# cloning the NodeGoat repo
cd /root/websploit
git clone https://github.com/OWASP/NodeGoat.git

# replacing the docker-compose.yml file with my second bridge network (10.7.7.0/24)
curl -sSL https://websploit.org/nodegoat-docker-compose.yml > /root/websploit/NodeGoat/docker-compose.yml

# downloading the nodegoat.sh script from websploit
# this will be used manually to setup the NodeGoat environment
cd /root/websploit/NodeGoat
wget https://websploit.org/nodegoat.sh
chmod 744 nodegoat.sh 

# Installing Gorilla-CLI to be used in AI-related training
pip3 install gorilla-cli


#Installing Knock
cd /root/websploit
git clone https://github.com/guelfoweb/knock.git
cd knock
python3 setup.py install

#Installing OWASP ZAP
apt install -y zaproxy

#Getting the container info script
sudo cd /root/websploit
curl -sSL https://websploit.org/containers.sh > /root/websploit/containers.sh

chmod +x /root/websploit/containers.sh
mv /root/websploit/containers.sh /usr/local/bin/containers 

#Final confirmation
sudo /usr/local/bin/containers
echo "
All set! All tools, apps, and containers have been installed and setup.
Have fun hacking! - Ωr
"
