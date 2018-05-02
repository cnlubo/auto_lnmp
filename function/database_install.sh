#!/bin/bash
# shellcheck disable=SC2164
# ----------------------------------------------------------------
#@Author          :              cnlubo (454331202@qq.com)
#@Filename       :              database_install.sh
#@desc           :
#------------------------------------------------------------------
system_check(){

    [[ "$OS" == '' ]] && echo "${CWARNING}[Error] Your system is not supported this script${CEND}" && exit
    [ ${RamTotal:?} -lt '1000' ] && echo -e "${CWARNING}[Error] Not enough memory install DataBase.\nThis script need memory more than 1G.\n${CEND}" && exit
}

select_database_install(){

    system_check
    echo "${CMSG}-----------------------------------------------------------------------${CEND}"
    cat << EOF
*  `echo -e "$CBLUE  1) MySQL        "`
*  `echo -e "$CBLUE  2) PostgreSQL   "`
*  `echo -e "$CBLUE  3) Back         "`
*  `echo -e "$CBLUE  4) Quit         "`
EOF
    read -p "${CBLUE}Which Version DataBase are you want to install:${CEND} " num3

    case $num3 in
        1)
            SOURCE_SCRIPT ${FunctionPath:?}/mysql_install.sh
            select_mysql_install
            ;;
        2)
            SOURCE_SCRIPT $FunctionPath/postgresql_install.sh
            select_postgresql_install
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
            select_database_install
    esac
}
