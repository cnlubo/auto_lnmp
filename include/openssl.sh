#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              openssl.sh
# @Desc
#----------------------------------------------------------------------------

Install_OpenSSL() {

    if [ ! -e ${openssl_install_dir:?}/lib/libcrypto.a ]; then
        cd ${script_dir:?}/src
        # shellcheck disable=SC2034
        src_url=https://www.openssl.org/source/openssl-${openssl_install_version:?}.tar.gz
        [ ! -f openssl-${openssl_install_version:?}.tar.gz ] && Download_src
        [ -d openssl-${openssl_install_version:?} ] && rm -rf openssl-${openssl_install_version:?}
        tar xf openssl-${openssl_install_version:?}.tar.gz && cd openssl-${openssl_install_version:?}
        ./config --prefix=${openssl_install_dir} shared zlib-dynamic
        make -j${CpuProNum:?} && make install
        if [ -f ${openssl_install_dir:?}/lib/libcrypto.a ]; then
            SUCCESS_MSG "[openssl-${openssl_install_version:?} installed successful !!!]"
            echo "${openssl_install_dir:?}/lib" > /etc/ld.so.conf.d/openssl.conf
            ldconfig
        else
            FAILURE_MSG "[install openssl-${openssl_install_version:?} failed,Please contact the author !!!]"
            # kill -9 $$
        fi
    fi

}

Install_OpenSSL_Main(){
    openssl_install_version=$1
    openssl_install_dir=$2
    Install_OpenSSL

}
