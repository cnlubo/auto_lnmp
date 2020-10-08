#!/bin/bash
# @Author: cnak47
# @Date: 2019-12-14 21:10:55
# @LastEditors: cnak47
# @LastEditTime: 2019-12-14 21:58:40
# @Description: 
# #
# shellcheck disable=SC1091
source ./color.sh
source ./common.sh
source ./check_os.sh
source ../config/common.conf
source ../apps.conf
source ../options.conf
source ./openssl.sh

Update_OpenSSL_Main "${openssl_latest_version:?}" "${openssl11_install_dir:?}"
    
