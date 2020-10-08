#!/bin/bash
# @Author: cnak47
# @Date: 2020-01-03 16:47:00
# @LastEditors: cnak47
# @LastEditTime: 2020-03-29 10:49:12
# @Description: 
# #

# shellcheck disable=SC1091
source ./color.sh
source ./common.sh
source ./check_os.sh
source ../config/common.conf
source ../apps.conf
source ../options.conf
source ./zsh.sh

[[ $(id -u) != '0' ]] && EXIT_MSG "Please use root to run this script."

install_zsh

