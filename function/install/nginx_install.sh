#!/bin/bash

# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              nginx_install.sh
# @Desc                                    nginx install scripts
#----------------------------------------------------------------------------

Nginx_Var() {

    if ! check_app_status "Nginx"; then
        WARNING_MSG "[nginx or Tengine is running please stop !!!!]" && exit 0
    fi
    INFO_MSG "[create user and group ] ********>>"
    if ! id "${run_user:?}" >/dev/null 2>&1; then
        #     WARNING_MSG "[ running user($run_user) exist !!!]"
        # else
        app_user_setup "${run_user:?}"
    fi
    # only run for CentOS 7.x
    if [[ "${CentOS_RHEL_version:?}" = '7' ]]; then
        # Disable Apache if installed
        if [[ "$(
            rpm -ql httpd >/dev/null 2>&1
            echo $?
        )" = '0' ]]; then
            if [[ "$(systemctl is-enabled httpd.service)" = 'enabled' ]]; then
                systemctl stop httpd.service
                systemctl disable httpd.service
            else
                systemctl disable httpd.service
            fi
        fi
    fi
}

Nginx_Base_Dep_Install() {

    if [[ "${gperftools_sourceinstall:?}" = [yY] ]]; then
        SOURCE_SCRIPT "${script_dir:?}"/include/google-perftools.sh
        install_gperftools
    else
        SOURCE_SCRIPT "${script_dir:?}"/include/jemalloc.sh
        Install_Jemalloc
    fi
    # pcre
    # shellcheck disable=SC2034
    src_url=https://sourceforge.net/projects/pcre/files/pcre/${nginx_pcrever:?}/pcre-$nginx_pcrever.tar.gz/download
    pcrefile="pcre-${nginx_pcrever}.tar.gz"
    pcredir=pcre-"$nginx_pcrever"
    [ ! -f "${pcrefile:?}" ] && Download_src && mv download "${pcrefile:?}"
    [ -d "$pcredir" ] && rm -rf "$pcredir"
    tar xf "$pcrefile"
    # && cd pcre-$pcre_version
    # ./configure --prefix=/usr/local/software/pcre --enable-utf8 --enable-unicode-properties
    # make && make install

    cd "${script_dir:?}"/src
    if [[ "${cloudflare_zlib:?}" = [yY] ]]; then
        if [ ! -d "zlib-cloudflare-${cloudflare_zlibver:?}" ]; then
            git clone https://github.com/cloudflare/zlib "zlib-cloudflare-${cloudflare_zlibver}"
        elif [ -d "zlib-cloudflare-${cloudflare_zlibver}/.git" ]; then
            cd "zlib-cloudflare-${cloudflare_zlibver}"
            git stash && git pull
        fi
        zlb_dir="zlib-cloudflare-${cloudflare_zlibver:?}"
    else
        # shellcheck disable=SC2034
        src_url=http://zlib.net/zlib-${zlib_version:?}.tar.gz
        [ ! -f zlib-"${zlib_version:?}".tar.gz ] && Download_src
        [ -d zlib-"${zlib_version:?}" ] && rm -rf zlib-"${zlib_version:?}"
        tar xf zlib-"${zlib_version:?}".tar.gz
        # shellcheck disable=SC2034
        zlb_dir=zlib-"${zlib_version:?}"
    fi
    # openssl
    cd "${script_dir:?}"/src
    # if [ "$Nginx_install" == 'Nginx' ] || [ "$Nginx_install" == 'Tengine' ]; then
    INFO_MSG "[ Openssl-${openssl_latest_version:?} ]*****************>>"
    openssl_file="openssl-${openssl_latest_version:?}.tar.gz"
    openssl_dir="openssl-${openssl_latest_version:?}"
    # shellcheck disable=SC2034
    src_url=https://www.openssl.org/source/$openssl_file
    [ ! -f "$openssl_file" ] && Download_src
    [ -d "$openssl_dir" ] && rm -rf "$openssl_dir"
    tar xf "$openssl_file"
    # else
    #     echo -e "${CMSG}[ Openssl-${openssl_version:?} ]***********************************>>${CEND}\n"
    #     # openssl
    #     # shellcheck disable=SC2034
    #     cd ${script_dir:?}/src
    #     src_url=https://www.openssl.org/source/openssl-${openssl_version:?}.tar.gz
    #     [ ! -f openssl-${openssl_version:?}.tar.gz ] && Download_src
    #     [ -d openssl-${openssl_version:?} ] && rm -rf openssl-${openssl_version:?}
    #     tar xf openssl-${openssl_version:?}.tar.gz
    # fi

    if [ "$Nginx_install" == 'Nginx' ] || [ "$Nginx_install" == 'OpenResty' ]; then

        INFO_MSG "[ngx_brotli ]******************>>"
        cd "${script_dir:?}"/src
        if [ ! -d ngx_brotli ]; then
            git clone --recursive https://github.com/google/ngx_brotli.git
        fi
        cd ngx_brotli && git submodule update --init
        cd deps/brotli
        grep 'BROTLI_VERSION' c/common/version.h
        brotlilatest_tag=$(git tag | tail -1)
        brotlibranch=$(echo "$brotlilatest_tag" | sed -e 's|v|local-|')
        echo "$brotlilatest_tag"
        echo "$brotlibranch"
        git stash
        git checkout "$brotlilatest_tag" -b "$brotlibranch"
        grep 'BROTLI_VERSION' c/common/version.h
    #     src_url=https://github.com/grahamedgecombe/nginx-ct/archive/v${ngx_ct_version:?}.tar.gz
    #     [ ! -f v${ngx_ct_version:?}.tar.gz ] && Download_src
    #     [ -d nginx-ct-${ngx_ct_version:?} ] && rm -rf nginx-ct-${ngx_ct_version:?}
    #     tar xf v${ngx_ct_version:?}.tar.gz
    fi

    if [ "${lua_install:?}" = 'y' ]; then
        yum -y install readline readline-deve
        SOURCE_SCRIPT "${script_dir:?}"/include/LuaJIT.sh
        install_openresty_luajit2

        INFO_MSG "[ ngx_devel_kit（NDK）]***************>>"
        cd "${script_dir:?}"/src || exit
        ngx_devel_kit_file=v${ngx_devel_kit_version:?}.tar.gz
        ngx_devel_kit_dir=ngx_devel_kit-${ngx_devel_kit_version:?}
        src_url=https://github.com/simplresty/ngx_devel_kit/archive/$ngx_devel_kit_file
        [ ! -f "$ngx_devel_kit_file" ] && Download_src
        [ -d "$ngx_devel_kit_dir" ] && rm -rf "$ngx_devel_kit_dir"
        tar xf "$ngx_devel_kit_file"

        INFO_MSG "[ lua-nginx-module（NDK）]*****************>>"
        cd "${script_dir:?}"/src
        lua_nginx_module_file=v${lua_nginx_module_version:?}.tar.gz
        lua_nginx_module_dir=lua-nginx-module-${lua_nginx_module_version:?}
        # shellcheck disable=SC2034
        src_url=https://github.com/openresty/lua-nginx-module/archive/$lua_nginx_module_file
        [ ! -f "$lua_nginx_module_file" ] && Download_src
        [ -d "$lua_nginx_module_dir" ] && rm -rf "$lua_nginx_module_dir"
        tar xf "$lua_nginx_module_file"

        INFO_MSG "[ stream-lua-nginx-module ]****************>>"
        cd "${script_dir:?}"/src
        if [ ! -d stream-lua-nginx-module ]; then
            git clone https://github.com/openresty/stream-lua-nginx-module.git
        else
            cd stream-lua-nginx-module && git pull
        fi
    fi

    
    # other
    yum -y install gcc automake autoconf libtool make gcc-c++
}

select_nginx_install() {

    echo "${CMSG}-----------------------------------------------------------------------${CEND}"
    cat <<EOF
*  $(echo -e "$CMAGENTA  1) Nginx-${nginx_mainline_version:?}   ")
*  $(echo -e "$CMAGENTA  2) Nginx-${nginx_mainline_version:?} with lua")
*  $(echo -e "$CMAGENTA  3) Tengine-${Tengine_version:?} ")
*  $(echo -e "$CMAGENTA  4) OpenResty-${openresty_version:?}     ")
*  $(echo -e "$CMAGENTA  5) Back             ")
*  $(echo -e "$CMAGENTA  6) Quit             ")
EOF
    # shellcheck disable=SC2162
    read -p "${CBLUE}Which Version are you want to install:${CEND} " num3

    case $num3 in
    1)
        SOURCE_SCRIPT "${FunctionPath:?}"/install/Nginx.sh
        # shellcheck disable=SC2034
        nginx_install_version=${nginx_mainline_version:?}
        Nginx_install='Nginx'
        lua_install='n'
        # shellcheck disable=SC2034
        Passenger_install='n'
        Nginx_Install_Main 2>&1 | tee "$script_dir"/logs/Install_Nginx.log
        select_nginx_install
        ;;
    2)
        SOURCE_SCRIPT "${FunctionPath:?}"/install/Nginx.sh
        # shellcheck disable=SC2034
        nginx_install_version=${nginx_mainline_version:?}
        Nginx_install='Nginx'
        # shellcheck disable=SC2034
        lua_install='y'
        # shellcheck disable=SC2034
        Passenger_install='n'
        Nginx_Install_Main 2>&1 | tee "$script_dir"/logs/Install_Nginx.log
        select_nginx_install
        ;;
    3)
        SOURCE_SCRIPT "${FunctionPath:?}"/install/Tengine.sh
        # shellcheck disable=SC2034
        tengine_install_version=${Tengine_version:?}
        Nginx_install='Tengine'
        lua_install='y'
        # shellcheck disable=SC2034
        Passenger_install='n'
        Tengine_Install_Main 2>&1 | tee "$script_dir"/logs/Install_Tengine.log
        select_nginx_install
        ;;

    4)
        SOURCE_SCRIPT "${FunctionPath:?}"/install/OpenResty.sh
        # shellcheck disable=SC2034
        OpenResty_install_version=${openresty_version:?}
        Nginx_install='OpenResty'
        lua_install='n'
        # shellcheck disable=SC2034
        Passenger_install='n'
        OpenResty_Install_Main 2>&1 | tee "$script_dir"/logs/Install_OpenResty.log
        select_nginx_install
        ;;
    5)
        select_web_install
        ;;
    6)
        clear
        exit 0
        ;;
    *)
        select_nginx_install
        ;;
    esac
}
