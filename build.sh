#!/bin/bash

mkdir built
wget https://github.com/gohugoio/hugo/releases/download/v0.38.1/hugo_0.38.1_Linux-64bit.tar.gz
tar -xvzf hugo*.tar.gz
./hugo
