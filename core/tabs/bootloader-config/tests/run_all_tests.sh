#!/bin/sh 

cd "$(dirname "$0")" || exit 1

./test_grub.sh
./test_systemd.sh
