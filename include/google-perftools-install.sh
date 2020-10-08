#!/bin/bash
# @Author: cnak47
# @Date: 2020-03-29 16:02:14
# @LastEditors: cnak47
# @LastEditTime: 2020-03-29 16:25:36
# @Description: 
# #

# shellcheck disable=SC1091
source ./color.sh
source ./common.sh
source ./check_os.sh
source ../config/common.conf
source ../apps.conf
source ../options.conf
source ./google-perftools.sh

[[ $(id -u) != '0' ]] && EXIT_MSG "Please use root to run this script."

install_gperftools