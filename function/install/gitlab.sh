#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              gitlab.sh
# @Desc
#----------------------------------------------------------------------------
Setup_DataBase() {

    case   ${gitlab_dbtype:?} in
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
                        PGDATABASE=template1 PGHOST=$PgsqlHost
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
                INFO_MSG "[ Create GitLab Database ........]"

                # test Gitlab db is exists
                if [ "$($PgsqlPath/bin/psql -lqt | cut -d \| -f 1 | grep -qw 'gitlabhq_production')" ] \
                    || [ "$($PgsqlPath/bin/psql -t -d postgres -c '\du' | cut -d \| -f 1 | grep -w 'git')" ]; then
                    while :; do
                        read -n1 -p "GitLab Db and User exists Do You Want to Delete? [y/n]: " del_yn
                        if [[ ! ${del_yn} =~ ^[y,n]$ ]]; then
                            WARNING_MSG "[input error! Please only input 'y' or 'n' ....]"
                        else
                            if [ "${del_yn}" == 'y' ]; then
                                echo
                                INFO_MSG "[ Drop Gitlab User and Db ........]"
                                $PgsqlPath/bin/psql -c " DROP DATABASE  IF EXISTS gitlabhq_production;"
                                $PgsqlPath/bin/psql -c " DROP ROLE IF EXISTS git;"
                            else
                                echo
                                FAILURE_MSG "[ GitLab DataBase can not Create  !!!]" && exit 0
                            fi
                            break
                        fi
                    done
                fi
                INFO_MSG "[ Create GitLab User and Db .........]"
                gitlab_pass=`mkpasswd -s 0 -l 8`
                $PgsqlPath/bin/psql -c " CREATE USER git CREATEDB;"
                $PgsqlPath/bin/psql -c " ALTER USER git with password '$gitlab_pass';"
                $PgsqlPath/bin/psql -c " CREATE EXTENSION IF NOT EXISTS pg_trgm;"
                $PgsqlPath/bin/psql -c "CREATE DATABASE gitlabhq_production template template1 OWNER git;"
                 unset PGUSER PGPASSWORD PGDATABASE PGHOST
                PGUSER='git'
                PGPASSWORD=$gitlab_pass
                PGDATABASE='gitlabhq_production'
                PGHOST=$PgsqlHost
                export PGUSER PGPASSWORD PGDATABASE PGHOST
                if $PgsqlPath/bin/psql -lqt | cut -d \| -f 1 | grep -qw $PGDATABASE ; then
                    # database exists
                    # $? is 0
                    SUCCESS_MSG "[ GitLab DataBase Create SUCCESS !!!!]"
                    WARNING_MSG "[ User git passwd:$gitlab_pass !!!!!!!]"
                else
                    # ruh-roh
                    # $? is 1
                    FAILURE_MSG "[ GitLab DataBase Create failure  !!!]"
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

Install_GitLab (){

    INFO_MSG "[ GitLab System Users .........]"
    id git >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        WARNING_MSG "[ GitLab user git already exists !!!]"
    else
        useradd git -s /usr/local/bin/zsh -d /home/git -c 'GitLab'
        default_pass=`mkpasswd -l 8`
        echo ${default_pass:?} | passwd git --stdin  &>/dev/null
        echo
        echo "${CRED}[GitLab user git passwd:${default_pass:?} !!!!! ] ****>>${CEND}" | tee ${script_dir:?}/logs/pp.log
        echo
    fi
    INFO_MSG "[ GitLab Database Setuping.........]"
    Setup_DataBase
}

Gitlab_Install_Main() {

    GitLab_Var && GitLab_Dep_Install && Install_GitLab

}
