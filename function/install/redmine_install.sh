#!/bin/bash

# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              redmine_install.sh
# @Desc
#----------------------------------------------------------------------------
SOURCE_SCRIPT ${script_dir:?}/include/check_db.sh

Redmine_Var() {

    check_app_status ${redmine_dbtype:?}
    if [ $? -eq 0 ]; then
        WARNING_MSG "[ PostgreSQL has been install .........]"
    else
        WARNING_MSG "[DataBase ${redmine_dbtype:?} is not running or install  !!!!]" && exit 0
    fi
}

# Nginx_Base_Dep_Install() {
#
#     echo -e "${CMSG}[zlib pcre jemalloc ]********************************>>${CEND}\n"
#     cd ${script_dir:?}/src
#     # zlib
#     # shellcheck disable=SC2034
#     src_url=http://zlib.net/zlib-${zlib_version:?}.tar.gz
#     [ ! -f zlib-${zlib_version:?}.tar.gz ] && Download_src
#     [ -d zlib-${zlib_version:?} ] && rm -rf zlib-${zlib_version:?}
#     tar xf zlib-${zlib_version:?}.tar.gz
#     # && cd zlib-${zlib_version:?}
#     # ./configure --prefix=/usr/local/software/sharelib && make && make install
#     # cd ..
#     # pcre
#     # shellcheck disable=SC2034
#     src_url=https://sourceforge.net/projects/pcre/files/pcre/${pcre_version:?}/pcre-$pcre_version.tar.gz/download
#     [ ! -f pcre-$pcre_version.tar.gz ] && Download_src && mv download pcre-$pcre_version.tar.gz
#     [ -d pcre-$pcre_version ] && rm -rf pcre-$pcre_version
#     tar xf pcre-$pcre_version.tar.gz
#     # && cd pcre-$pcre_version
#     # ./configure --prefix=/usr/local/software/pcre --enable-utf8 --enable-unicode-properties
#     # make && make install
#     # cd ..
#     # jemalloc
#     SOURCE_SCRIPT ${script_dir:?}/include/jemalloc.sh
#     Install_Jemalloc
#     # openssl
#     if [ $Nginx_install == 'Nginx' ] || [ $Nginx_install == 'Tengine' ]; then
#
#         echo -e "${CMSG}[ Openssl-${openssl_latest_version:?} ]***********************************>>${CEND}\n"
#         # shellcheck disable=SC2034
#         cd ${script_dir:?}/src
#         src_url=https://www.openssl.org/source/openssl-${openssl_latest_version:?}.tar.gz
#         [ ! -f openssl-${openssl_latest_version:?}.tar.gz ] && Download_src
#         [ -d openssl-${openssl_latest_version:?} ] && rm -rf openssl-${openssl_latest_version:?}
#         tar xf openssl-${openssl_latest_version:?}.tar.gz
#     else
#         echo -e "${CMSG}[ Openssl-${openssl_version:?} ]***********************************>>${CEND}\n"
#         # openssl
#         # shellcheck disable=SC2034
#         cd ${script_dir:?}/src
#         src_url=https://www.openssl.org/source/openssl-${openssl_version:?}.tar.gz
#         [ ! -f openssl-${openssl_version:?}.tar.gz ] && Download_src
#         [ -d openssl-${openssl_version:?} ] && rm -rf openssl-${openssl_version:?}
#         tar xf openssl-${openssl_version:?}.tar.gz
#     fi
#     # ngx_brotli ngx-ct
#     if [ $Nginx_install == 'Nginx' ] || [ $Nginx_install == 'OpenResty' ]; then
#
#         echo -e "${CMSG}[ngx_brotli ngx-ct ]*************************>>${CEND}\n"
#         #[ -d ngx_brotli ] && rm -rf ngx_brotli
#         #git clone https://github.com/google/ngx_brotli.git
#         #cd ngx_brotli && git submodule update --init
#         if  [ ! -d ngx_brotli ]; then
#             git clone https://github.com/google/ngx_brotli.git
#             cd ngx_brotli && git submodule update --init
#         fi
#         src_url=https://github.com/grahamedgecombe/nginx-ct/archive/v${ngx_ct_version:?}.tar.gz
#         [ ! -f v${ngx_ct_version:?}.tar.gz ] && Download_src
#         [ -d nginx-ct-${ngx_ct_version:?} ] && rm -rf nginx-ct-${ngx_ct_version:?}
#         tar xf v${ngx_ct_version:?}.tar.gz
#     fi
#     # echo-nginx-module
#     if [ $Nginx_install == 'Nginx' ] || [ $Nginx_install == 'Tengine' ]; then
#
#         echo -e "${CMSG}[ echo-nginx-module ]*************************>>${CEND}\n"
#         [ -d echo-nginx-module ] && rm -rf echo-nginx-module
#         git clone https://github.com/openresty/echo-nginx-module.git
#     fi
#
#     echo -e "${CMSG}[ ngx_pagespeed ]*************************>>${CEND}\n"
#     cd ${script_dir:?}/src
#     src_url=https://github.com/apache/incubator-pagespeed-ngx/archive/v${pagespeed_version:?}.tar.gz
#     [ ! -f v${pagespeed_version:?}.tar.gz ] && Download_src
#     [ -d incubator-pagespeed-ngx-${pagespeed_version:?} ] && rm -rf incubator-pagespeed-ngx-${pagespeed_version:?}
#     tar xf v${pagespeed_version:?}.tar.gz
#     src_url=https://dl.google.com/dl/page-speed/psol/${psol_version:?}-x$OS_BIT.tar.gz
#     [ ! -f ${psol_version:?}-x$OS_BIT.tar.gz ] && Download_src
#     mv ${psol_version:?}-x$OS_BIT.tar.gz  incubator-pagespeed-ngx-${pagespeed_version:?}/ && cd incubator-pagespeed-ngx-${pagespeed_version:?}
#     [ -d psol ] && rm -rf psol
#     tar xf ${psol_version:?}-x$OS_BIT.tar.gz
#
#
#     if [ ${lua_install:?} = 'y' ]; then
#         yum -y install readline readline-deve
#         SOURCE_SCRIPT ${script_dir:?}/include/LuaJIT.sh
#         Install_LuaJIT
#         echo -e "${CMSG}[ ngx_devel_kit（NDK）]***********************************>>${CEND}\n"
#         cd ${script_dir:?}/src
#         src_url=https://github.com/simplresty/ngx_devel_kit/archive/v${ngx_devel_kit_version:?}.tar.gz
#         [ ! -f v${ngx_devel_kit_version:?}.tar.gz ] && Download_src
#         [ -d ngx_devel_kit-${ngx_devel_kit_version:?} ] && rm -rf ngx_devel_kit-${ngx_devel_kit_version:?}
#         tar xf v${ngx_devel_kit_version:?}.tar.gz
#         echo -e "${CMSG}[ lua-nginx-module（NDK）]***********************************>>${CEND}\n"
#         cd ${script_dir:?}/src
#         # shellcheck disable=SC2034
#         src_url=https://github.com/openresty/lua-nginx-module/archive/v${lua_nginx_module_version:?}.tar.gz
#         [ ! -f v${lua_nginx_module_version:?}.tar.gz ] && Download_src
#         [ -d lua-nginx-module-${lua_nginx_module_version:?} ] && rm -rf lua-nginx-module-${lua_nginx_module_version:?}
#         tar xf v${lua_nginx_module_version:?}.tar.gz
#         echo -e "${CMSG}[ stream-lua-nginx-module ]***********************************>>${CEND}\n"
#         cd ${script_dir:?}/src
#         if  [ ! -d stream-lua-nginx-module ]; then
#             git clone https://github.com/openresty/stream-lua-nginx-module.git
#         else
#             cd stream-lua-nginx-module && git pull
#         fi
#     fi
#     # other
#     yum -y install gcc automake autoconf libtool make gcc-c++ libuuid-devel
# }

select_redmine_install(){

    echo "${CMSG}-----------------------------------------------------------------------${CEND}"
    cat << EOF
*  `echo -e "$CMAGENTA  1) Redmine-${redmine_verion:?}   "`
*  `echo -e "$CMAGENTA  2) Nginx-${nginx_mainline_version:?} with Passenger"`
*  `echo -e "$CMAGENTA  3) Redmine Common plug-in "`
*  `echo -e "$CMAGENTA  4) Upgrade Redmine "`
*  `echo -e "$CMAGENTA  5) Back             "`
*  `echo -e "$CMAGENTA  6) Quit             "`
EOF
    read -p "${CBLUE}Which function are you want to select:${CEND} " num3

    case $num3 in
        1)
            SOURCE_SCRIPT ${FunctionPath:?}/install/redmine.sh
            Redmine_Install_Main
            select_redmine_install
            ;;
        2)
            select_devops_install
            ;;
        3)
            select_devops_install
            ;;

        4)
            select_devops_install
            ;;
        5)
            select_devops_install
            ;;
        6)
            clear
            exit 0
            ;;
        *)
            select_redmine_install
    esac
}
