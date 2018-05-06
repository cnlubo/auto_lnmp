#!/bin/bash
# shellcheck disable=SC2034
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# # @file_name:                              check_db.sh
# @Desc
#----------------------------------------------------------------------------

function  check_app_status () {

    # return 0:running 1:not run 9: unkonw App
    app_name=$1
    case   ${app_name:?} in
        "postgreSQL")
            {
                COUNT=$(ps aux|grep postgres|grep -v grep |wc -l)
                if [ $COUNT -gt 0 ]
                then
                    return 0
                else
                    return 1
                fi
            }
            ;;
        "MySql")
            {
                COUNT=$(ps aux|grep mysqld|grep -v grep |wc -l)
                if [ $COUNT -gt 0 ]
                then
                    return 0
                else
                    return 1
                fi
            }
            ;;
        *)
            echo "unknow App ${db_type:?}" && return 9 ;;
    esac
}

check_postgresql() {

    check_app_status "postgreSQL"
    if [ $? -eq 0 ]; then
        WARNING_MSG "[ PostgreSQl is not running or install !!!]" && exit
    fi
}