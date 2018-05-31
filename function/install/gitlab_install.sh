#!/bin/bash

# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              gitlab_install.sh
# @Desc
#----------------------------------------------------------------------------
SOURCE_SCRIPT ${ScriptPath:?}/config/postgresql.conf
SOURCE_SCRIPT ${script_dir:?}/config/gitlab.conf
SOURCE_SCRIPT ${script_dir:?}/config/redis.conf

GitLab_Var() {

    check_app_status ${gitlab_dbtype:?}
    if [ $? -eq 1 ]; then
        WARNING_MSG "[DataBase ${gitlab_dbtype:?} is not running or install  !!!!]" && exit 0
    fi
    check_app_status "Redis"
    if [ $? -eq 0 ]; then
        WARNING_MSG "[Redis12 is running Please stop and remove it !!!!]" && exit 0
    fi
}

Nginx_GitLab_Conf() {

    check_app_status "Nginx"
    if [ $? -eq 0 ]; then
        if [ -f /home/git/gitlab/lib/support/nginx/gitlab ]; then
            INFO_MSG "[ Config Nginx for GitLab.........]"
            cp /home/git/gitlab/lib/support/nginx/gitlab ${nginx_install_dir:?}/conf.d/gitlab.conf
            sed -i 's@listen[[:space:]]\[::\]:80.*@#&@g' ${nginx_install_dir:?}/conf.d/gitlab.conf
            sed -i 's@server_name.*@server_name localhost;@g' ${nginx_install_dir:?}/conf.d/gitlab.conf
            sed -i "s@access_log.*@access_log  ${nginx_install_dir:?}/logs/gitlab_access.log gitlab_access;@g" ${nginx_install_dir:?}/conf.d/gitlab.conf
            sed -i "s@error_log.*@error_log   ${nginx_install_dir:?}/logs/gitlab_error.log;@g" ${nginx_install_dir:?}/conf.d/gitlab.conf
            [ -f ${nginx_install_dir:?}/conf.d/default.conf ] && rm -rf ${nginx_install_dir:?}/conf.d/default.conf
            systemctl restart nginx
            INFO_MSG "[Check Install and Run State ......]"
            cd /home/git/gitlab
            sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production

        else
            WARNING_MSG "[Gitlab is not Install !!!!]"
            exit 1
        fi
    else
        WARNING_MSG "[Nginx is not Install !!!!]"
        exit 1
    fi
}

Install_Redis() {

    SOURCE_SCRIPT ${FunctionPath:?}/install/Redis_install.sh
    # shellcheck disable=SC2034
    listen_type='sock'
    #Redis_Install_Main 2>&1 | tee ${script_dir:?}/logs/Install_Redis.log
    Redis_Var && Redis_Dep_Install && Install_Redis
    # check redis status
    ERROR_MSG=`${redis_install_dir:?}/bin/redis-cli -a ${redispass:?} -s ${redissock:?} PING`
    if [ "$ERROR_MSG" != "PONG" ];then
        FAILURE_MSG "[Redis Install failure,Please contact the author !!!]"
    fi
}

GitLab_Dep_Install(){

    INFO_MSG "[ Ruby、rubygem Installing.........]"
    SOURCE_SCRIPT ${script_dir:?}/include/ruby.sh
    Install_Ruby
    INFO_MSG "[ Golang Installing.........]"
    SOURCE_SCRIPT ${script_dir:?}/include/golang.sh
    install_golang
    INFO_MSG "[ Redis Installing.........]"
    Install_Redis
    INFO_MSG "[ Node.js v8.x Installing.........]"
    curl --silent --location https://rpm.nodesource.com/setup_8.x | bash -
    yum -y install nodejs
    npm install -g yarn
    # other
    yum -y install libicu-devel re2-devel
}

select_gitlab_install(){

    echo "${CMSG}-----------------------------------------------------------------------${CEND}"
    cat << EOF
*  `echo -e "$CMAGENTA  1) Gitlab-${gitlab_verson:?}   "`
*  `echo -e "$CMAGENTA  2) Nginx-${nginx_mainline_version:?}"`
*  `echo -e "$CMAGENTA  3) Upgrade Gitlab "`
*  `echo -e "$CMAGENTA  4) Back             "`
*  `echo -e "$CMAGENTA  5) Quit             "`
EOF
    # exec 3<&0 </dev/null
    #read -r var <&3
    read -p "${CBLUE}Which function1 are you want to select:${CEND} " num3

    case $num3 in
        1)
            SOURCE_SCRIPT ${FunctionPath:?}/install/gitlab.sh
            Gitlab_Install_Main 2>&1 | tee $script_dir/logs/Install_GitLab.log
            echo
            select_gitlab_install
            ;;
        2)
            SOURCE_SCRIPT ${FunctionPath:?}/install/nginx_install.sh
            SOURCE_SCRIPT ${FunctionPath:?}/install/Nginx.sh
            # shellcheck disable=SC2034
            nginx_install_version=${nginx_mainline_version:?}
            # shellcheck disable=SC2034
            Nginx_install='Nginx'
            # shellcheck disable=SC2034
            lua_install='n'
            # shellcheck disable=SC2034
            Passenger_install='n'
            Nginx_Var && Nginx_Base_Dep_Install && Install_Nginx
            Nginx_GitLab_Conf
            select_gitlab_install
            ;;
        3)
            select_devops_install
            ;;
        4)
            select_devops_install
            ;;
        5)
            clear
            exit 0
            ;;
        *)
            select_gitlab_install
    esac
}
