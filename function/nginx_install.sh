#!/bin/bash

# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              nginx_install.sh
# @Desc                                    nginx install scripts
#----------------------------------------------------------------------------

Nginx_Var() {

    #第二种，准确判断pid的信息，
    #-C 表示的是nginx完整命令，不带匹配的操作
    #--no-header 表示不要表头的数据
    #wc -l 表示计数
    COUNT=$(ps -C nginx --no-header |wc -l)
    #echo "ps -c|方法:"$COUNT
    if [ $COUNT -gt 0 ]
    then
        echo -e "${CWARNING}[Error nginx or Tengine is running please stop !!!!]${CEND}\n" && exit
    fi
    echo -e "${CMSG}[create user and group ]***********************************>>${CEND}\n"

    grep ${run_user:?} /etc/group >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        groupadd $run_user
    fi
    id $run_user >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        useradd -g $run_user  -M -s /sbin/nologin $run_user
    fi

}

Nginx_Base_Dep_Install() {

    echo -e "${CMSG}[zlib pcre jemalloc ]********************************>>${CEND}\n"
    cd ${script_dir:?}/src
    # zlib
    # shellcheck disable=SC2034
    src_url=http://zlib.net/zlib-${zlib_version:?}.tar.gz
    [ ! -f zlib-${zlib_version:?}.tar.gz ] && Download_src
    [ -d zlib-${zlib_version:?} ] && rm -rf zlib-${zlib_version:?}
    tar xf zlib-${zlib_version:?}.tar.gz
    # && cd zlib-${zlib_version:?}
    # ./configure --prefix=/usr/local/software/sharelib && make && make install
    # cd ..
    # pcre
    # shellcheck disable=SC2034
    src_url=https://sourceforge.net/projects/pcre/files/pcre/${pcre_version:?}/pcre-$pcre_version.tar.gz/download
    [ ! -f pcre-$pcre_version.tar.gz ] && Download_src && mv download pcre-$pcre_version.tar.gz
    [ -d pcre-$pcre_version ] && rm -rf pcre-$pcre_version
    tar xf pcre-$pcre_version.tar.gz
    # && cd pcre-$pcre_version
    # ./configure --prefix=/usr/local/software/pcre --enable-utf8 --enable-unicode-properties
    # make && make install
    # cd ..
    # jemalloc
    SOURCE_SCRIPT ${script_dir:?}/include/jemalloc.sh
    Install_Jemalloc
    # openssl
    if [ $Nginx_install == 'Nginx' ] || [ $Nginx_install == 'Tengine' ]; then

        echo -e "${CMSG}[ Openssl-${openssl_latest_version:?} ]***********************************>>${CEND}\n"
        # shellcheck disable=SC2034
        cd ${script_dir:?}/src
        src_url=https://www.openssl.org/source/openssl-${openssl_latest_version:?}.tar.gz
        [ ! -f openssl-${openssl_latest_version:?}.tar.gz ] && Download_src
        [ -d openssl-${openssl_latest_version:?} ] && rm -rf openssl-${openssl_latest_version:?}
        tar xf openssl-${openssl_latest_version:?}.tar.gz
    else
        echo -e "${CMSG}[ Openssl-${openssl_version:?} ]***********************************>>${CEND}\n"
        # openssl
        # shellcheck disable=SC2034
        cd ${script_dir:?}/src
        src_url=https://www.openssl.org/source/openssl-${openssl_version:?}.tar.gz
        [ ! -f openssl-${openssl_version:?}.tar.gz ] && Download_src
        [ -d openssl-${openssl_version:?} ] && rm -rf openssl-${openssl_version:?}
        tar xf openssl-${openssl_version:?}.tar.gz
    fi
    # ngx_brotli ngx-ct
    if [ $Nginx_install == 'Nginx' ] || [ $Nginx_install == 'OpenResty' ]; then

        echo -e "${CMSG}[ngx_brotli ngx-ct ]*************************>>${CEND}\n"
        #[ -d ngx_brotli ] && rm -rf ngx_brotli
        #git clone https://github.com/google/ngx_brotli.git
        #cd ngx_brotli && git submodule update --init
        if  [ ! -d ngx_brotli ]; then
            git clone https://github.com/google/ngx_brotli.git
            cd ngx_brotli && git submodule update --init
        fi
        src_url=https://github.com/grahamedgecombe/nginx-ct/archive/v${ngx_ct_version:?}.tar.gz
        [ ! -f v${ngx_ct_version:?}.tar.gz ] && Download_src
        [ -d nginx-ct-${ngx_ct_version:?} ] && rm -rf nginx-ct-${ngx_ct_version:?}
        tar xf v${ngx_ct_version:?}.tar.gz
    fi
    # echo-nginx-module
    if [ $Nginx_install == 'Nginx' ] || [ $Nginx_install == 'Tengine' ]; then

        echo -e "${CMSG}[ echo-nginx-module ]*************************>>${CEND}\n"
        [ -d echo-nginx-module ] && rm -rf echo-nginx-module
        git clone https://github.com/openresty/echo-nginx-module.git
    fi

    echo -e "${CMSG}[ ngx_pagespeed ]*************************>>${CEND}\n"
    cd ${script_dir:?}/src
    src_url=https://github.com/apache/incubator-pagespeed-ngx/archive/v${pagespeed_version:?}.tar.gz
    [ ! -f v${pagespeed_version:?}.tar.gz ] && Download_src
    [ -d incubator-pagespeed-ngx-${pagespeed_version:?} ] && rm -rf incubator-pagespeed-ngx-${pagespeed_version:?}
    tar xf v${pagespeed_version:?}.tar.gz
    src_url=https://dl.google.com/dl/page-speed/psol/${psol_version:?}-x$OS_BIT.tar.gz
    [ ! -f ${psol_version:?}-x$OS_BIT.tar.gz ] && Download_src
    mv ${psol_version:?}-x$OS_BIT.tar.gz  incubator-pagespeed-ngx-${pagespeed_version:?}/ && cd incubator-pagespeed-ngx-${pagespeed_version:?}
    [ -d psol ] && rm -rf psol
    tar xf ${psol_version:?}-x$OS_BIT.tar.gz


    if [ ${lua_install:?} = 'y' ]; then
        yum -y install readline readline-deve
        SOURCE_SCRIPT ${script_dir:?}/include/LuaJIT.sh
        Install_LuaJIT
        echo -e "${CMSG}[ ngx_devel_kit（NDK）]***********************************>>${CEND}\n"
        cd ${script_dir:?}/src
        src_url=https://github.com/simplresty/ngx_devel_kit/archive/v${ngx_devel_kit_version:?}.tar.gz
        [ ! -f v${ngx_devel_kit_version:?}.tar.gz ] && Download_src
        [ -d ngx_devel_kit-${ngx_devel_kit_version:?} ] && rm -rf ngx_devel_kit-${ngx_devel_kit_version:?}
        tar xf v${ngx_devel_kit_version:?}.tar.gz
        echo -e "${CMSG}[ lua-nginx-module（NDK）]***********************************>>${CEND}\n"
        cd ${script_dir:?}/src
        # shellcheck disable=SC2034
        src_url=https://github.com/openresty/lua-nginx-module/archive/v${lua_nginx_module_version:?}.tar.gz
        [ ! -f v${lua_nginx_module_version:?}.tar.gz ] && Download_src
        [ -d lua-nginx-module-${lua_nginx_module_version:?} ] && rm -rf lua-nginx-module-${lua_nginx_module_version:?}
        tar xf v${lua_nginx_module_version:?}.tar.gz
        echo -e "${CMSG}[ stream-lua-nginx-module ]***********************************>>${CEND}\n"
        cd ${script_dir:?}/src
        if  [ ! -d stream-lua-nginx-module ]; then
            git clone https://github.com/openresty/stream-lua-nginx-module.git
        else
            cd stream-lua-nginx-module && git pull
        fi
    fi
    # other
    yum -y install gcc automake autoconf libtool make gcc-c++
    # libuuid-devel
}

select_nginx_install(){

    echo "${CMSG}-----------------------------------------------------------------------${CEND}"
    cat << EOF
*  `echo -e "$CBLUE  1) Nginx-${nginx_mainline_version:?}   "`
*  `echo -e "$CBLUE  2) Nginx-${nginx_mainline_version:?} with lua"`
*  `echo -e "$CBLUE  3) Tengine-${Tengine_version:?} "`
*  `echo -e "$CBLUE  4) OpenResty-${openresty_version:?}     "`
*  `echo -e "$CBLUE  5) Back             "`
*  `echo -e "$CBLUE  6) Quit             "`
EOF
    read -p "${CBLUE}Which Version are you want to install:${CEND} " num3

    case $num3 in
        1)
            SOURCE_SCRIPT ${FunctionPath:?}/install/Nginx.sh
            # shellcheck disable=SC2034
            nginx_install_version=${nginx_mainline_version:?}
            Nginx_install='Nginx'
            lua_install='n'
            Nginx_Install_Main 2>&1 | tee $script_dir/logs/Install_Nginx.log
            select_nginx_install
            ;;
        2)
            SOURCE_SCRIPT ${FunctionPath:?}/install/Nginx.sh
            # shellcheck disable=SC2034
            nginx_install_version=${nginx_mainline_version:?}
            Nginx_install='Nginx'
            # shellcheck disable=SC2034
            lua_install='y'
            Nginx_Install_Main 2>&1 | tee $script_dir/logs/Install_Nginx.log
            select_nginx_install
            ;;
        3)
            SOURCE_SCRIPT ${FunctionPath:?}/install/Tengine.sh
            # shellcheck disable=SC2034
            tengine_install_version=${Tengine_version:?}
            Nginx_install='Tengine'
            lua_install='y'
            Tengine_Install_Main 2>&1 | tee $script_dir/logs/Install_Tengine.log
            select_nginx_install
            ;;

        4)
            SOURCE_SCRIPT ${FunctionPath:?}/install/OpenResty.sh
            # shellcheck disable=SC2034
            OpenResty_install_version=${openresty_version:?}
            Nginx_install='OpenResty'
            lua_install='n'
            OpenResty_Install_Main 2>&1 | tee $script_dir/logs/Install_OpenResty.log
            select_nginx_install
            ;;
        5)
            clear
            select_main_menu
            ;;
        6)
            clear
            exit 0
            ;;
        *)
            select_nginx_install
    esac
}
