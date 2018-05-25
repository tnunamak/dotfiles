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
ln -s ~/.config/nvim ~/.vim

curl --create-dirs -o ~/.vim/colors/distinguished.vim https://cdn.rawgit.com/Lokaltog/vim-distinguished/develop/colors/distinguished.vim

vim +PlugInstall +qall

# Requires cmake
cd ~/.vim/plugged/YouCompleteMe
./install.py

# Make a place for vim to put swap files
mkdir -p ~/.vim/tmp
