#!/bin/bash
# @Author: cnak47
# @Date: 2019-12-29 12:04:28
# @LastEditors: cnak47
# @LastEditTime: 2020-02-04 10:54:57
# @Description:
# #

install_cmake() {

    if [ "${OS}" == "CentOS" ]; then
        INFO_MSG " cmake${cmake3_version:?} install ....."
        cd "${script_dir:?}"/src || exit
        # shellcheck disable=SC2034
        src_url=https://github.com/Kitware/CMake/releases/download/v${cmake3_version:?}/cmake-${cmake3_version:?}.tar.gz
        [ -d cmake-"$cmake3_version" ] && rm -rf cmake-"$cmake3_version"
        [ ! -f cmake-"$cmake3_version".tar.gz ] && Download_src
        tar xf cmake-"$cmake3_version".tar.gz
        cd cmake-"${cmake3_version:?}" || exit
    fi
}
