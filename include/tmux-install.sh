#!/bin/bash
# @Author: cnak47
# @Date: 2020-01-03 11:54:58
# @LastEditors: cnak47
# @LastEditTime: 2020-01-03 11:55:06
# @Description: 
# #

# shellcheck disable=SC1091
source ./color.sh
source ./common.sh
source ./check_os.sh
source ../config/common.conf
source ../apps.conf
source ../options.conf
source ./tmux.sh

[[ $(id -u) != '0' ]] && EXIT_MSG "Please use root to run this script."

install_tmux
