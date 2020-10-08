#!/bin/bash
###
# @Author: cnak47
# @Date: 2018-04-30 23:59:11
# @LastEditors: cnak47
# @LastEditTime: 2020-03-29 11:34:41
# @Description:
###

Install_Jemalloc() {

    if [ -e "/usr/local/lib/libjemalloc.so" ]; then
        SUCCESS_MSG "[ jemalloc has been install !!! ]"
    else
        # shellcheck disable=SC2034
        src_url=https://github.com/jemalloc/jemalloc/releases/download/${jemalloc_version:?}/jemalloc-$jemalloc_version.tar.bz2
        cd "${script_dir:?}"/src || return
        [ ! -f jemalloc-"$jemalloc_version".tar.bz2 ] && Download_src
        [ -d jemalloc-"$jemalloc_version" ] && rm -rf jemalloc-"$jemalloc_version"
        tar xf jemalloc-"$jemalloc_version".tar.bz2
        cd jemalloc-"$jemalloc_version" || exit

        ./configure && make && make install
        if [ -f "/usr/local/lib/libjemalloc.so" ]; then
            echo '/usr/local/lib' >/etc/ld.so.conf.d/local.conf
            ldconfig
        else
            FAILURE_MSG " Jemalloc install failed, Please contact the author !!! "
            kill -9 $$
        fi
        # cd .. && rm -rf $script_dir/src/jemalloc-$jemalloc_version
    fi
}
