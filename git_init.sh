#!/bin/bash
#
##ensure ssh_keys are available in ~/.ssh and github account
##ensure repo url is set to ssh format ex.
#git remote set-url origin git@github.com:M3hran/scripts.git
#
#

apt update > /dev/null 2>&1
apt install -y git

eval `ssh-agent -s`
ssh-add ./.ssh/id_rsa

git config --global user.name M3hran
git config --global user.email m3hran@gmail.com
git config --global color.ui auto
git config --global init.defaultBranch master

ssh -T git@github.com

