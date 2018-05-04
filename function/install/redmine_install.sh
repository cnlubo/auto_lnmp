#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              redmine_install.sh
# @Desc
#----------------------------------------------------------------------------

Redmine_Var() {

    echo ""

}

Redis_Dep_Install(){

    INFO_MSG "[ Ruby、rubygem、rails Installing.........]"
    SOURCE_SCRIPT ${script_dir:?}/include/ruby.sh
    Install_Ruby
}
Install_Redmine(){

    echo
}

Config_Redmine(){


    echo ""

}

Redmine_Install_Main() {

    Redis_Dep_Install

}
