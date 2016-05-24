#!/bin/bash
if [ ! -f "~/.config/nvim/autoload/plug.vim" ]; then
    echo "Installing vim-plug";
    curl -fLo "~/.config/nvim/autoload/plug.vim" --create-dirs "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim";
else
    echo "vim-plug already installed"
fi
exit
