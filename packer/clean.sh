#!/bin/sh

set -e

pacman -Rs --noconfirm ansible
rm -rf /root/.ansible