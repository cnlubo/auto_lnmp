#!/bin/bash
# @Author: cnak47
# @Date: 2020-01-08 15:07:48
# @LastEditors: cnak47
# @LastEditTime: 2020-01-08 15:08:25
# @Description: 
# #

# shellcheck disable=SC1091
source ./color.sh
source ./common.sh
source ./check_os.sh
source ../config/common.conf
source ../apps.conf
source ../options.conf
source ./python3.sh

[[ $(id -u) != '0' ]] && EXIT_MSG "Please use root to run this script."

install_python36