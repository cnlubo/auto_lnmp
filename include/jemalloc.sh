#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              jemalloc.sh
# @Desc
#----------------------------------------------------------------------------

Install_Jemalloc() {

    if [ -e "/usr/local/lib/libjemalloc.so" ];then
        echo -e "${CMSG}[ jemalloc has been install !!! ] ****************************>>${CEND}\n"
    else
        # shellcheck disable=SC2034
        src_url=https://github.com/jemalloc/jemalloc/releases/download/${jemalloc_version:?}/jemalloc-$jemalloc_version.tar.bz2
        cd ${script_dir:?}/src
        [ ! -f jemalloc-$jemalloc_version.tar.bz2 ] && Download_src
        [ -d jemalloc-$jemalloc_version ] && rm -rf jemalloc-$jemalloc_version
        tar xvf jemalloc-$jemalloc_version.tar.bz2 && cd jemalloc-$jemalloc_version

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
    # if [ ! -e "/usr/local/lib/libjemalloc.so" ]; then
    #   pushd ${oneinstack_dir}/src
    #   tar xjf jemalloc-$jemalloc_version.tar.bz2
    #   pushd jemalloc-$jemalloc_version
    #   LDFLAGS="${LDFLAGS} -lrt" ./configure
    #   make -j ${THREAD} && make install
    #   unset LDFLAGS
    #   popd
    #   if [ -f "/usr/local/lib/libjemalloc.so" ]; then
    #     if [ "$OS_BIT" == '64' -a "$OS" == 'CentOS' ]; then
    #       ln -s /usr/local/lib/libjemalloc.so.2 /usr/lib64/libjemalloc.so.1
    #     else
    #       ln -s /usr/local/lib/libjemalloc.so.2 /usr/lib/libjemalloc.so.1
    #     fi
    #     echo '/usr/local/lib' > /etc/ld.so.conf.d/local.conf
    #     ldconfig
    #     echo "${CSUCCESS}jemalloc module installed successfully! ${CEND}"
    #     rm -rf jemalloc-${jemalloc_version}
    #   else
    #     echo "${CFAILURE}jemalloc install failed, Please contact the author! ${CEND}"
    #     kill -9 $$
    #   fi
    #   popd
    # fi
}
