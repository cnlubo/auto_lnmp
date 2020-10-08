#!/bin/bash
# @Author: cnak47
# @Date: 2020-01-08 16:36:54
# @LastEditors: cnak47
# @LastEditTime: 2020-01-08 16:37:32
# @Description: 
# #

# shellcheck disable=SC1091
source ./color.sh
source ./common.sh
source ./check_os.sh
source ../config/common.conf
source ../apps.conf
source ../options.conf
source ./vim.sh

[[ $(id -u) != '0' ]] && EXIT_MSG "Please use root to run this script."

install_vim
