#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              redmine_install.sh
# @Desc
#----------------------------------------------------------------------------

# check_prerequisites () {
#
#     check_app_status "postgreSQL"
#     if [ $? -eq 0 ]; then
#         WARNING_MSG "[PostgreSQL is not running or install  !!!!]"
#     fi
# }

Redmine_Var() {

    check_app_status ${redmine_dbtype:?}
    if [ $? -eq 0 ]; then
        WARNING_MSG "[DataBase ${redmine_dbtype:?} is not running or install  !!!!]" && exit 0
    fi
}

Redmine_Dep_Install(){

    INFO_MSG "[ Ruby、rubygem、rails Installing.........]"
    SOURCE_SCRIPT ${script_dir:?}/include/ruby.sh
    Install_Ruby

}

Setup_DataBase() {

    case   ${redmine_dbtype:?} in
        "postgreSQL")
            {

                while :; do
                    echo
                    read -p "Please input PostgreSQL install path (Default:${pgsqlbasepath:?}:" PgsqlPath
                    PgsqlPath="${PgsqlPath:=${pgsqlbasepath:?}}"
                    if [ ! -x $PgsqlPath/bin/psql ]; then
                        FAILURE_MSG "[ $PgsqlPath/bin/psql not exists  !!!]"
                    else
                        break
                    fi
                done

                while :; do
                    echo
                    read -p "Please input PostgreSQL run user (Default:${pgsql_user:?}:" PgsqlUser
                    PgsqlUser="${PgsqlUser:=${pgsql_user:?}}"
                    id $PgsqlUser >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        break
                    else
                        FAILURE_MSG "[ User $PgsqlUser not exists  !!!]"
                    fi
                done
                read -p "Please input PostgreSQL host  (Default:localhost):" PgsqlHost
                PgsqlHost="${PgsqlHost:=localhost}"

                read -p "Please input PostgreSQL password :" PgsqlPass
                PgsqlPass="${PgsqlPass}"


            }
            ;;

        "MySql")
            {
                echo
            }
            ;;
        *)
            echo "unknow Dbtype" && exit ;;
    esac
}

Install_Redmine(){

    INFO_MSG "[ redmine-${redmine_verion:?} Installing.........]"
    cd ${script_dir:?}/src
    # shellcheck disable=SC2034
    src_url=https://www.redmine.org/releases/redmine-${redmine_verion:?}.tar.gz
    [ ! -f redmine-${redmine_verion:?}.tar.gz ] && Download_src
    [ -d redmine-${redmine_verion:?} ] && rm -rf redmine-${redmine_verion:?}
    tar xf redmine-${redmine_verion:?}.tar.gz
    [ -d ${wwwroot_dir:?}/redmine ] && rm -rf ${wwwroot_dir:?}/redmine
    mv redmine-${redmine_verion:?} ${wwwroot_dir:?}/redmine

}

Config_Redmine(){


    echo ""


}


Redmine_Install_Main() {

    Redmine_Var && Redmine_Dep_Install

}
