#!/bin/bash
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              init_system.sh
# @Desc
#----------------------------------------------------------------------------
select_system_setup_function(){

    echo "${CMSG}[Initialization $OS] **************************************************>>${CEND}";
#    if [ "$OS" == 'CentOS' ];then
#        . include/init_CentOS.sh 2>&1 | tee $ScriptPath/logs/init_os.log
#        [ -n "`gcc --version | head -n1 | grep '4\.1\.'`" ] && export CC="gcc44" CXX="g++44"
#        elif [ "$OS" == 'Debian' ];then
#        . include/init_Debian.sh 2>&1 | tee $ScriptPath/logs/init_os.log
#        elif [ "$OS" == 'Ubuntu' ];then
#        . include/init_Ubuntu.sh 2>&1 | tee $ScriptPath/logs/init_os.log
#    fi
    echo "${CMSG}[Initialization $OS OK please reboot] **************************************************>>${CEND}";
    select_main_menu;
}
