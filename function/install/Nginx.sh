#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              Nginx.sh
# @Desc
#----------------------------------------------------------------------------

Nginx_stable_install(){

    echo -e "${CMSG}[nginx-${ngix_stable_version:?} install begin ]***********************>>${CEND}\n"
    echo -e "${CMSG}[step1 zlib pcre jemalloc openssl ]***********************************>>${CEND}\n"
    cd ${script_dir:?}/src
    # zlib
    # shellcheck disable=SC2034
    src_url=http://zlib.net/zlib-${zlib_version:?}.tar.gz
    [ ! -f zlib-${zlib_version:?}.tar.gz ] && Download_src
    [ -d zlib-${zlib_version:?} ] && rm -rf zlib-${zlib_version:?}
    tar xvf zlib-${zlib_version:?}.tar.gz
    # && cd zlib-${zlib_version:?}
    # ./configure --prefix=/usr/local/software/sharelib && make && make install
    # cd ..
    # pcre
    # shellcheck disable=SC2034
    src_url=https://sourceforge.net/projects/pcre/files/pcre/${pcre_version:?}/pcre-$pcre_version.tar.gz/download
    [ ! -f pcre-$pcre_version.tar.gz ] && Download_src && mv download pcre-$pcre_version.tar.gz
    [ -d pcre-$pcre_version ] && rm -rf pcre-$pcre_version
    tar xvf pcre-$pcre_version.tar.gz
    # && cd pcre-$pcre_version
    # ./configure --prefix=/usr/local/software/pcre --enable-utf8 --enable-unicode-properties
    # make && make install
    # cd ..
    #
    # openssl
    # shellcheck disable=SC2034
    src_url=https://www.openssl.org/source/openssl-${openssl_version:?}.tar.gz
    [ ! -f openssl-${openssl_version:?}.tar.gz ] && Download_src
    [ -d openssl-${openssl_version:?} ] && rm -rf openssl-${openssl_version:?}
    tar xvf openssl-${openssl_version:?}.tar.gz
    # jemalloc
    SOURCE_SCRIPT ${script_dir:?}/include/jemalloc.sh
    Install_Jemalloc
    # other
    yum -y install gcc automake autoconf libtool make gcc-c++
    # ngx_brotli
    echo -e "${CMSG}[step2 support ngx_brotli ]***********************************>>${CEND}\n"
    cd ${script_dir:?}/src
    [ -d ngx_brotli ] && rm -rf ngx_brotli
    git clone https://github.com/google/ngx_brotli.git
    cd ngx_brotli && git submodule update --init && cd ..
    echo -e "${CMSG}[step3 create user and group ]***********************************>>${CEND}\n"
    grep ${run_user:?} /etc/group >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        groupadd $run_user
    fi
    id $run_user >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        useradd -g $run_user  -M -s /sbin/nologin $run_user
    fi



}
