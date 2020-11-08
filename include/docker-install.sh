#!/bin/bash
# @Author: cnak47
# @Date: 2019-12-28 17:36:41
# @LastEditors: cnak47
# @LastEditTime: 2020-11-07 22:39:35
# @Description:
# #
# shellcheck disable=SC1091
source ./color.sh
source ./common.sh
source ./check_os.sh
source ../config/common.conf
source ../apps.conf
source ../options.conf
source ./docker.sh
[[ $(id -u) != '0' ]] && EXIT_MSG "Please use root to run this script."
Install_Docker
