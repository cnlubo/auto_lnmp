#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              harbor_install.sh
# @Desc
#----------------------------------------------------------------------------
Harbor_Var() {

    echo
}

Harbor_Dep_Install(){

    SOURCE_SCRIPT ${script_dir:?}/include/docker.sh
    Install_Docker
}

Harbor_Install_Main() {

    Harbor_Var && Harbor_Dep_Install

}
