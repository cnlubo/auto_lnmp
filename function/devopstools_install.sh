#!/bin/bash
# shellcheck disable=SC2164
# ----------------------------------------------------------------
#@Author          :              cnlubo (454331202@qq.com)
#@Filename       :               devopstools_install.sh
#@desc           :
#------------------------------------------------------------------


select_devops_install(){

    system_check
    echo "${CMSG}-----------------------------------------------------------------------${CEND}"
    cat << EOF
*  `echo -e "$CBLUE  1) GitLab-${gitlab_verson:?} "`
*  `echo -e "$CBLUE  2) Gogs-${gogs_verson:?}     "`
*  `echo -e "$CBLUE  3) Redmine-${redmine_verion:?} "`
*  `echo -e "$CBLUE  4) Back         "`
*  `echo -e "$CBLUE  5) Quit         "`
EOF
    read -p "${CBLUE}Which tools are you want to install:${CEND} " num3

    case $num3 in
        1)
            SOURCE_SCRIPT ${FunctionPath:?}/install/gitlab_install.sh
            select_gitlab_install
            ;;
        2)
            clear
            select_main_menu
            ;;
        3)
            SOURCE_SCRIPT ${FunctionPath:?}/install/redmine_install.sh
            select_redmine_install
            ;;
        4)
            clear
            select_main_menu
            ;;
        5)
            clear
            exit 0
            ;;
        *)
            select_devops_install
    esac
}
