#!/bin/bash\
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              nginx_install.sh
# @Desc                                    nginx install scripts
#----------------------------------------------------------------------------
select_nginx_install(){

    echo "${CMSG}-----------------------------------------------------------------------${CEND}"
    cat << EOF
*  `echo -e "$CBLUE  1) Nginx-${nginx_mainline_version:?}   "`
*  `echo -e "$CBLUE  2) Nginx-${nginx_mainline_version:?} with lua"`
*  `echo -e "$CBLUE  3) Tengine-${Tengine_version:?}"`
*  `echo -e "$CBLUE  4) OpenResty        "`
*  `echo -e "$CBLUE  5) Back             "`
*  `echo -e "$CBLUE  6) Quit             "`
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
            nginx_install_version=${nginx_stable_version:?}
            # shellcheck disable=SC2034
            lua_install='y'
            Nginx_Install_Main
            select_nginx_install
        ;;
        3)
            SOURCE_SCRIPT ${FunctionPath:?}/install/Tengine.sh
            # shellcheck disable=SC2034
            tengine_install_version=${Tengine_version:?}
            Tengine_Install_Main
            select_nginx_install
        ;;
        4)
            clear
            select_main_menu
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
