#!/usr/bin/env bash
#
# Assumes https://github.com/neovim/neovim is installed
#

curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

mkdir -p ~/.config/nvim
ln -s "$(pwd)/init.vim" ~/.config/nvim/init.vim
ln -s ~/.config/nvim/init.vim ~/.vimrc

# ln -s ./.nvim ~/.config/nvim

# Map ~/.vim/autoload (vim is linked to ~/.config/nvim)
ln -s ~/.local/share/nvim/site/autoload ~/.config/nvim/autoload
# Create ~/.vim as a link to nvim
ln -s ~/.config/nvim ~/.vim

curl --create-dirs -o ~/.vim/colors/distinguished.vim https://cdn.jsdelivr.net/gh/Lokaltog/vim-distinguished@develop/colors/distinguished.vim

vim +PlugInstall +qall

# Requires cmake
cd ~/.vim/plugged/YouCompleteMe
./install.py

# Make a place for vim to put swap files
mkdir -p ~/.vim/tmp
