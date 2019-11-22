#!/usr/bin/env bash
#
sudo apt-get install -y software-properties-common

sudo add-apt-repository ppa:neovim-ppa/stable
sudo apt-get update

sudo apt-get install -y neovim python-dev python-pip python3-dev python3-pip

pip2 install --user --upgrade neovim
pip2 install --upgrade pip
pip3 install --user --upgrade neovim
pip3 install --upgrade pip

sudo apt-get install build-essential cmake

curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
sudo apt-get install -y nodejs silversearcher-ag
