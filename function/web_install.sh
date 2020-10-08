#!/bin/bash
# @Author: cnak47
# @Date: 2018-05-02 17:33:25
# @LastEditors: cnak47
# @LastEditTime: 2020-03-29 09:59:58
# @Description: 
# #
# system_check(){
#
#     [[ "$OS" == '' ]] && echo "${CWARNING}[Error] Your system is not supported this script${CEND}" && exit
#     [ ${RamTotal:?} -lt '1000' ] && echo -e "${CWARNING}[Error] Not enough memory install.\nThis script need memory more than 1G.\n${CEND}" && exit
# }

select_web_install(){

    system_check
    echo "${CMSG}-----------------------------------------------------------------------${CEND}"
    cat << EOF
*  $(echo -e "$CBLUE  1) Nginx        ")
*  $(echo -e "$CBLUE  2) Tomcat       ")
*  $(echo -e "$CBLUE  3) Back         ")
*  $(echo -e "$CBLUE  4) Quit         ")
EOF
    read -r -p "${CBLUE}Which Version Web Server are you want to install:${CEND} " num3

    case $num3 in
        1)
            SOURCE_SCRIPT "${FunctionPath:?}"/install/nginx_install.sh
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
