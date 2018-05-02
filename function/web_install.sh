#!/bin/bash
# shellcheck disable=SC2164
# ----------------------------------------------------------------
#@Author          :              cnlubo (454331202@qq.com)
#@Filename       :               web_install.sh
#@desc           :               web Server install
#------------------------------------------------------------------
system_check(){

    [[ "$OS" == '' ]] && echo "${CWARNING}[Error] Your system is not supported this script${CEND}" && exit
    [ ${RamTotal:?} -lt '1000' ] && echo -e "${CWARNING}[Error] Not enough memory install.\nThis script need memory more than 1G.\n${CEND}" && exit
}

select_web_install(){

    system_check
    echo "${CMSG}-----------------------------------------------------------------------${CEND}"
    cat << EOF
*  `echo -e "$CBLUE  1) Nginx        "`
*  `echo -e "$CBLUE  2) Tomcat       "`
*  `echo -e "$CBLUE  3) Back         "`
*  `echo -e "$CBLUE  4) Quit         "`
EOF
    read -p "${CBLUE}Which Version Web Server are you want to install:${CEND} " num3

    case $num3 in
        1)
            SOURCE_SCRIPT ${FunctionPath:?}/install/nginx_install.sh
            select_nginx_install
            ;;
        2)
            clear
            select_main_menu
            ;;
        3)
            clear
            select_main_menu
            ;;
        4)
            clear
            exit 0
            ;;
        *)
            select_web_install
    esac
}
