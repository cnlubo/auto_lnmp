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
SOURCE_SCRIPT ${script_dir:?}/include/check_db.sh

Redmine_Var() {

    check_app_status ${redmine_dbtype:?}
    if [ $? -eq 0 ]; then
        WARNING_MSG "[ PostgreSQL has been install .........]"
    else
        WARNING_MSG "[DataBase ${redmine_dbtype:?} is not running or install  !!!!]" && exit 0
    fi
}

Redmine_Dep_Install(){

    INFO_MSG "[ Ruby、rubygem、rails Installing.........]"
    SOURCE_SCRIPT ${script_dir:?}/include/ruby.sh
    Install_Ruby
    INFO_MSG "[ Redmine Database Setuping.........]"
    Setup_DataBase

}

Setup_DataBase() {

    case   ${redmine_dbtype:?} in
        "postgreSQL")
            {
                while :; do
                    while :; do
                        read -p "Please input PostgreSQL install path (Default:${pgsqlbasepath:?}):" PgsqlPath
                        PgsqlPath="${PgsqlPath:=${pgsqlbasepath:?}}"
                        if [ ! -x $PgsqlPath/bin/psql ]; then
                            FAILURE_MSG "[ $PgsqlPath/bin/psql not exists  !!!]"
                        else
                            break
                        fi
                    done

                    while :; do
                        read -p "Please input PostgreSQL run user (Default:${pgsqluser:?}):" PgsqlUser
                        PgsqlUser="${PgsqlUser:=${pgsqluser:?}}"
                        id $PgsqlUser >/dev/null 2>&1
                        if [ $? -eq 0 ]; then
                            break
                        else
                            FAILURE_MSG "[ User $PgsqlUser not exists  !!!]"
                        fi
                    done
                    read -p "Please input PostgreSQL host (Default:localhost):" PgsqlHost
                    PgsqlHost="${PgsqlHost:=localhost}"

                    read -s -p "Please input PostgreSQL password :" PgsqlPass
                    PgsqlPass="${PgsqlPass}"
                    echo
                    export PGUSER=$PgsqlUser PGPASSWORD=$PgsqlPass \
                    PGDATABASE=postgres PGHOST$PgsqlHost
                    pg_version=$($PgsqlPath/bin/psql -A -t -c "show server_version")
                    if [ -z $pg_version ]; then
                        FAILURE_MSG "[ PostgreSQL connect error  !!!]"
                        unset PGUSER PGPASSWORD PGDATABASE PGHOST
                    else
                        break
                    fi
                done
                #major=$(echo $pg_version | cut -d. -f1,2)
                #minor=$(echo $pg_version | cut -d. -f3)
                INFO_MSG "[ current PostgreSQL version is $pg_version ........]"
                INFO_MSG "[ Create Redmine Database ........]"
                # test redmine db is exists
                if [ "$($PgsqlPath/bin/psql -lqt | cut -d \| -f 1 | grep -qw 'redmine')" ] \
                    || [ "$($PgsqlPath/bin/psql -t -d postgres -c '\du' | cut -d \| -f 1 | grep -w 'redmine')" ]; then
                    while :; do echo
                        read -n1 -p "Db and User exists Do You Want to Delete? [y/n]: " del_yn
                        if [[ ! ${del_yn} =~ ^[y,n]$ ]]; then
                            WARNING_MSG "[input error! Please only input 'y' or 'n' ....]"
                        else
                            if [ "${del_yn}" == 'y' ]; then
                                $PgsqlPath/bin/psql -c " DROP DATABASE  IF EXISTS redmine;"
                                $PgsqlPath/bin/psql -c " DROP ROLE IF EXISTS redmine;"
                            else
                                exit 0
                            fi
                            break
                        fi
                    done
                fi

                # create user and database
                redmine_pass=`mkpasswd -l 8`
                $PgsqlPath/bin/psql -c " CREATE ROLE redmine LOGIN ENCRYPTED PASSWORD '$redmine_pass' NOINHERIT VALID UNTIL 'infinity';"
                $PgsqlPath/bin/psql -c "CREATE DATABASE redmine WITH ENCODING='UTF8' OWNER=redmine;"
                unset PGUSER PGPASSWORD PGDATABASE PGHOST
                PGUSER='redmine'
                PGPASSWORD=$redmine_pass
                PGDATABASE='redmine'
                PGHOST=$PgsqlHost
                export PGUSER PGPASSWORD PGDATABASE PGHOST
                if $PgsqlPath/bin/psql -lqt | cut -d \| -f 1 | grep -qw $PGDATABASE ; then
                    # database exists
                    # $? is 0
                    SUCCESS_MSG "[ Redmine DataBase Create SUCCESS !!!!]"
                    WARNING_MSG "[ User remine passwd:$redmine_pass !!!!!!!]"
                else
                    # ruh-roh
                    # $? is 1
                    FAILURE_MSG "[ Redmine DataBase Create failure  !!!]"
                    unset PGUSER PGPASSWORD PGDATABASE PGHOST
                    kill -9 $$
                fi
                unset PGUSER PGPASSWORD PGDATABASE PGHOST

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
