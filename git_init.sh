#!/bin/bash

#ensure ssh_keys are available in ~/.ssh and github account
#ensure repo url is set to ssh format ex.
#git remote set-url origin git@github.com:M3hran/scripts.git

git config --global user.name M3hran
git config --global user.email m3hran@gmail.com
git config --global color.ui auto

ssh -T git@github.com
