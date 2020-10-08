#!/bin/bash
# @Author: cnak47
# @Date: 2020-01-11 11:45:39
# @LastEditors: cnak47
# @LastEditTime: 2020-01-11 11:46:26
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

install_vim_plugin