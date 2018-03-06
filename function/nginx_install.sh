#!/bin/bash\
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              nginx_install.sh
# @Desc                                    nginx install scripts
#----------------------------------------------------------------------------

Nginx_Var() {
    # echo ${nginx_install_version:?}
    #第二种，准确判断pid的信息，
    #-C 表示的是nginx完整命令，不带匹配的操作
    #--no-header 表示不要表头的数据
    #wc -l 表示计数
    COUNT=$(ps -C nginx --no-header |wc -l)
    #echo "ps -c|方法:"$COUNT
    if [ $COUNT -gt 0 ]
    then
        echo -e "${CWARNING}[Error nginx or Tengine is running please stop !!!!]${CEND}\n" && select_nginx_install
    fi

}

Nginx_Base_Dep_Install() {

    echo -e "${CMSG}[zlib pcre jemalloc openssl ]********************************>>${CEND}\n"
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
    if [ ${lua_install:?} = 'y' ]; then
        SOURCE_SCRIPT ${script_dir:?}/include/LuaJIT.sh
        Install_LuaJIT
        echo -e "${CMSG}[ ngx_devel_kit（NDK）]***********************************>>${CEND}\n"
        cd ${script_dir:?}/src
        src_url=https://github.com/simplresty/ngx_devel_kit/archive/v${ngx_devel_kit_version:?}.tar.gz
        [ ! -f v${ngx_devel_kit_version:?}.tar.gz ] && Download_src
        [ -d ngx_devel_kit-${ngx_devel_kit_version:?} ] && rm -rf ngx_devel_kit-${ngx_devel_kit_version:?}
        tar xvf v${ngx_devel_kit_version:?}.tar.gz
        echo -e "${CMSG}[ lua-nginx-module（NDK）]***********************************>>${CEND}\n"
        cd ${script_dir:?}/src
        # shellcheck disable=SC2034
        src_url=https://github.com/openresty/lua-nginx-module/archive/v${lua_nginx_module_version:?}.tar.gz
        [ ! -f v${lua_nginx_module_version:?}.tar.gz ] && Download_src
        [ -d lua-nginx-module-${lua_nginx_module_version:?} ] && rm -rf lua-nginx-module-${lua_nginx_module_version:?}
        tar xvf v${lua_nginx_module_version:?}.tar.gz
    fi
}

select_nginx_install(){

    echo "${CMSG}-----------------------------------------------------------------------${CEND}"
    cat << EOF
*  `echo -e "$CBLUE  1) Nginx-${nginx_mainline_version:?}   "`
*  `echo -e "$CBLUE  2) Nginx-${nginx_mainline_version:?} with lua"`
*  `echo -e "$CBLUE  3) Tengine-${Tengine_version:?}"`
*  `echo -e "$CBLUE  4) Tengine-${Tengine_version:?} with lua"`
*  `echo -e "$CBLUE  5) OpenResty-${openresty_version:?}     "`
*  `echo -e "$CBLUE  6) Back             "`
*  `echo -e "$CBLUE  7) Quit             "`
EOF
    read -p "${CBLUE}Which Version are you want to install:${CEND} " num3

    case $num3 in
        1)
            SOURCE_SCRIPT ${FunctionPath:?}/install/Nginx.sh
            # shellcheck disable=SC2034
            nginx_install_version=${nginx_mainline_version:?}
            lua_install='n'
            Nginx_Install_Main
            select_nginx_install
        ;;
        2)
            SOURCE_SCRIPT ${FunctionPath:?}/install/Nginx.sh
            # shellcheck disable=SC2034
            nginx_install_version=${nginx_mainline_version:?}
            # shellcheck disable=SC2034
            lua_install='y'
            Nginx_Install_Main
            select_nginx_install
        ;;
        3)
            SOURCE_SCRIPT ${FunctionPath:?}/install/Tengine.sh
            # shellcheck disable=SC2034
            tengine_install_version=${Tengine_version:?}
            lua_install='n'
            Tengine_Install_Main
            select_nginx_install
        ;;
        4)
            SOURCE_SCRIPT ${FunctionPath:?}/install/Tengine.sh
            # shellcheck disable=SC2034
            tengine_install_version=${Tengine_version:?}
            lua_install='y'
            Tengine_Install_Main
            select_nginx_install
        ;;

        5)
            clear
            select_main_menu
        ;;
        6)
            clear
            select_main_menu
        ;;
        7)
            clear
            exit 0
        ;;
        *)
            select_nginx_install
    esac
}
