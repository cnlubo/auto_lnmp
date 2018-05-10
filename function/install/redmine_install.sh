#!/bin/bash

# shellcheck disable=SC2164
# shellcheck disable=SC2034
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              redmine_install.sh
# @Desc
#----------------------------------------------------------------------------
SOURCE_SCRIPT ${ScriptPath:?}/config/postgresql.conf

Redmine_Var() {

    check_app_status ${redmine_dbtype:?}
    if [ $? -eq 0 ]; then
        WARNING_MSG "[ PostgreSQL installed .........]"
    else
        WARNING_MSG "[DataBase ${redmine_dbtype:?} is not running or install  !!!!]" && exit 0
    fi
}

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
            SOURCE_SCRIPT ${FunctionPath:?}/install/nginx_install.sh
            nginx_install_version=${nginx_mainline_version:?}
            Nginx_install='Nginx'
            lua_install='y'
            Nginx_Var && Nginx_Base_Dep_Install
            select_redmine_install
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
