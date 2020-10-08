#!/bin/bash
# shellcheck disable=SC2164
###
# @Author: cnak47
# @Date: 2018-05-02 16:50:28
# @LastEditors: cnak47
# @LastEditTime: 2020-01-21 14:33:10
# @Description:
###

# system_check(){
#
#     [[ "$OS" == '' ]] && echo "${CWARNING}[Error] Your system is not supported this script${CEND}" && exit
#     [ ${RamTotal:?} -lt '1000' ] && echo -e "${CWARNING}[Error] Not enough memory install DataBase.\nThis script need memory more than 1G.\n${CEND}" && exit
# }

select_database_install() {

    system_check
    echo "${CMSG}-----------------------------------------------------------------------${CEND}"
    # shellcheck disable=SC2006
    cat <<EOF
*  $(echo -e "$CBLUE  1) MySQL        ")
*  $(echo -e "$CBLUE  2) MariaDB      ")
*  $(echo -e "$CBLUE  3) PostgreSQL   ")
*  $(echo -e "$CBLUE  4) Redis        ")
*  $(echo -e "$CBLUE  5) Back         ")
*  $(echo -e "$CBLUE  6) Quit         ")
EOF
    read -r -p "${CBLUE}Which Version DataBase are you want to install:${CEND} " num3

    case $num3 in
    1)
        SOURCE_SCRIPT "${FunctionPath:?}"/install/mysql_install.sh
        select_mysql_install
        ;;
    2)
        SOURCE_SCRIPT "${FunctionPath:?}"/install/mariadb_install.sh
        select_mariadb_install
        ;;
    3)
        SOURCE_SCRIPT "$FunctionPath"/install/postgresql_install.sh
        select_postgresql_install
        ;;
    4)
        SOURCE_SCRIPT "$FunctionPath"/install/Redis_install.sh
        # shellcheck disable=SC2034
        listen_type='tcp'
        Redis_Install_Main 2>&1 | tee "${script_dir:?}"/logs/Install_Redis.log
        select_database_install
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
        select_database_install
        ;;
    esac
}
