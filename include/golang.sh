#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              golang.sh
# @Desc
#----------------------------------------------------------------------------


install_golang(){

    if [ -f "${go_install_dir:?}/go/bin/go" ];then
        SUCCESS_MSG "[ golang is already installed ......]"
    else
        # shellcheck disable=SC2034
        src_url=https://dl.google.com/go/go${go_version:?}.linux-amd64.tar.gz
        # INFO_MSG "[ Go-${go_version:?} installing ]"
        cd ${script_dir:?}/src
        [ ! -f go${go_version:?}.linux-amd64.tar.gz ] && Download_src
        [ -d ${go_install_dir:?}/go ] && rm -rf ${go_install_dir:?}/go
        tar -C ${go_install_dir:?} -xf go${go_version:?}.linux-amd64.tar.gz
        ln -sf ${go_install_dir:?}/go/bin/{go,godoc,gofmt} /usr/local/bin/
        if [ -f "${go_install_dir:?}/go/bin/go" ];then
            SUCCESS_MSG "[go-${go_version:?} Install success !!!]"
        else
            FAILURE_MSG "[ go install failed, Please contact the author !!!]"
            kill -9 $$
        fi
    fi
}
