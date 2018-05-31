#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              jemalloc.sh
# @Desc
#----------------------------------------------------------------------------

Install_Jemalloc() {

    if [ -e "/usr/local/lib/libjemalloc.so" ];then
        SUCCESS_MSG "[ jemalloc has been install !!! ]"
    else
        # shellcheck disable=SC2034
        src_url=https://github.com/jemalloc/jemalloc/releases/download/${jemalloc_version:?}/jemalloc-$jemalloc_version.tar.bz2
        cd ${script_dir:?}/src
        [ ! -f jemalloc-$jemalloc_version.tar.bz2 ] && Download_src
        [ -d jemalloc-$jemalloc_version ] && rm -rf jemalloc-$jemalloc_version
        tar xf jemalloc-$jemalloc_version.tar.bz2 && cd jemalloc-$jemalloc_version

        ./configure && make && make install
        if [ -f "/usr/local/lib/libjemalloc.so" ];then
            echo '/usr/local/lib' > /etc/ld.so.conf.d/local.conf
            ldconfig
        else
            echo "${CFAILURE}[ jemalloc install failed, Please contact the author !!!] ****************************>>${CEND}"
            kill -9 $$
        fi
        # cd .. && rm -rf $script_dir/src/jemalloc-$jemalloc_version
    fi
}
