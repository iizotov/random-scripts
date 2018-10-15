#!/bin/bash

sudo apt-get install bash-completion

alias k='kubectl'
source <(kubectl completion bash)
source <(kubectl completion bash | sed 's/kubectl/k/g')

echo "alias k='kubectl'" >> >> ~/.bashrc
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "source <(kubectl completion bash | sed 's/kubectl/k/g')" >> ~/.bashrc

echo "autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab" >> ~/.vimrc
echo "autocmd FileType yml setlocal ts=2 sts=2 sw=2 expandtab" >> ~/.vimrc
