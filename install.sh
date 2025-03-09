#!/bin/sh

echo "Making sure git is installed ..."
apt update
apt install git

cd /etc
git clone https://github.com/Benrogo-Dev/PyGitHook.git

sh install_stage2.sh