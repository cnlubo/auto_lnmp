#!/bin/bash
###
# @Author: cnak47
# @Date: 2018-04-30 23:59:11
# @LastEditors: cnak47
# @LastEditTime: 2020-05-17 10:23:50
# @Description:
###
Install_OpenSSL() {

    # clean up recent no-tls1_3 bug
    if [ -d /usr/local/ssl ]; then
        INFO_MSG "clean up no-tls1_3 bug /usr/local/ssl"
        rm -rf /usr/local/ssl
    fi
    if [ -d /usr/local/lib/engines-1.1 ]; then
        INFO_MSG "clean up no-tls1_3 bug /usr/local/lib/engines-1.1"
        rm -rf /usr/local/lib/engines-1.1
    fi
    if [ -d /usr/local/include/openssl ]; then
        INFO_MSG "clean up no-tls1_3 bug /usr/local/include/openssl"
        rm -rf /usr/local/include/openssl
    fi
    if [ -f /usr/local/bin/openssl ]; then
        INFO_MSG "clean up no-tls1_3 bug /usr/local/bin/openssl"
        rm -rf /usr/local/bin/openssl
    fi
    if [ -f /usr/local/bin/c_rehash ]; then
        INFO_MSG "clean up no-tls1_3 bug /usr/local/bin/c_rehash"
        rm -rf /usr/local/bin/c_rehash
    fi
    if [ -f /usr/local/lib/libssl.a ]; then
        INFO_MSG "clean up old /usr/local/lib/libssl.a"
        rm -rf /usr/local/lib/libssl.a
        ldconfig
    fi
    if [ -f /usr/local/lib/libcrypto.a ]; then
        INFO_MSG "clean up old /usr/local/lib/libcrypto.a"
        rm -rf /usr/local/lib/libcrypto.a
        ldconfig
    fi

    if [ ! -e "${openssl_install_dir:?}"/lib/libcrypto.a ]; then

        INFO_MSG "[openssl-${openssl_install_version:?} begin install !!!]"
        cd "${script_dir:?}"/src || exit
        # shellcheck disable=SC2034
        src_url=https://www.openssl.org/source/openssl-${openssl_install_version:?}.tar.gz
        [ ! -f openssl-"${openssl_install_version:?}".tar.gz ] && Download_src
        [ -d openssl-"${openssl_install_version:?}" ] && rm -rf openssl-"${openssl_install_version:?}"
        tar xf openssl-"${openssl_install_version:?}".tar.gz
        cd openssl-"${openssl_install_version:?}" || exit
        ./config --prefix="${openssl_install_dir}" shared zlib-dynamic
        make -j"${CpuProNum:?}" && make install
        if [ -f "${openssl_install_dir:?}"/lib/libcrypto.a ]; then
            SUCCESS_MSG "[openssl-${openssl_install_version:?} installed successful !!!]"
            echo "${openssl_install_dir:?}/lib" >/etc/ld.so.conf.d/openssl.conf
            ldconfig
            rm -rf /usr/local/include/openssl && ln -s "${openssl_install_dir:?}"/include/openssl /usr/local/include/openssl
        else
            FAILURE_MSG "[install openssl-${openssl_install_version:?} failed,Please contact the author !!!]"
            # kill -9 $$
        fi
    fi

}

Install_OpenSSL_Main() {
    openssl_install_version=$1
    openssl_install_dir=$2
    Install_OpenSSL

}

Update_OpenSSL_Main() {
    openssl_install_version=$1
    openssl_install_dir=$2
    if [ -e "${openssl_install_dir:?}"/lib/libcrypto.a ]; then
        rm -rf "${openssl_install_dir:?}"/lib/libcrypto.a
    fi
    Install_OpenSSL

}
