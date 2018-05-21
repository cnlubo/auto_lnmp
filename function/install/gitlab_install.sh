#!/bin/bash

# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              gitlab_install.sh
# @Desc
#----------------------------------------------------------------------------
SOURCE_SCRIPT ${ScriptPath:?}/config/postgresql.conf
SOURCE_SCRIPT ${script_dir:?}/config/gitlab.conf

GitLab_Var() {

    check_app_status ${gitlab_dbtype:?}
    if [ $? -eq 1 ]; then
        WARNING_MSG "[DataBase ${gitlab_dbtype:?} is not running or install  !!!!]" && exit 0
    fi
    check_app_status'Redis'
    if [ $? -eq 1 ]; then
        WARNING_MSG "[Redis is not running or install  !!!!]" && exit 0
    fi
}

GitLab_Dep_Install(){

    INFO_MSG "[ Ruby、rubygem Installing.........]"
    SOURCE_SCRIPT ${script_dir:?}/include/ruby.sh
    Install_Ruby
    INFO_MSG "[ Golang Installing.........]"
    SOURCE_SCRIPT ${script_dir:?}/include/golang.sh
    install_golang
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
*  `echo -e "$CMAGENTA  2) Nginx-${nginx_mainline_version:?} with Passenger"`
*  `echo -e "$CMAGENTA  3) Upgrade Gitlab "`
*  `echo -e "$CMAGENTA  4) Back             "`
*  `echo -e "$CMAGENTA  5) Quit             "`
EOF
    read -p "${CBLUE}Which function are you want to select:${CEND} " num3

    case $num3 in
        1)
            SOURCE_SCRIPT ${FunctionPath:?}/install/gitlab.sh
            Gitlab_Install_Main 2>&1 | tee $script_dir/logs/Install_GitLab.log
            select_gitlab_install
            ;;
        2)
            select_devops_install
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
