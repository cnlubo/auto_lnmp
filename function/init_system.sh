#!/bin/bash
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @Date:                                   2016-02-18 12:01:28
# @file_name:                              init_system.sh
# @Last Modified by:                       ak47
# @Last Modified time:                     2016-02-18 17:33:10
# @Desc
#----------------------------------------------------------------------------
SELECT_SYSTEM_SETUP_FUNCTION(){

    # declare -a VarLists
    # echo "[Notice] Which version tomcat are you want to install:"
    # VarLists=("Back" "tomcat7" "tomcat8")
    # select var in ${VarLists[@]} ;do
    #     case $var in
    #         ${VarLists[1]})
    #             SOURCE_SCRIPT $FunctionPath/install/tomcat-7.sh
    #             Install_tomcat-7;;
    #         ${VarLists[2]})
    #             SOURCE_SCRIPT $FunctionPath/install/tomcat-8.sh
    #             TOMCAT_VAR && SELECT_TOMCAT_FUNCTION;;
    #         ${VarLists[0]})
    #             SELECT_RUN_SCRIPT;;
    #         *)
    #             SELECT_TOMCAT_INSTALL;;
    #     esac
    #     break
    # done
    echo "${CMSG}[Initialization $OS] **************************************************>>${CEND}";
    if [ "$OS" == 'CentOS' ];then
        . include/init_CentOS.sh 2>&1 | tee $ScriptPath/logs/init_os.log
        [ -n "`gcc --version | head -n1 | grep '4\.1\.'`" ] && export CC="gcc44" CXX="g++44"
    elif [ "$OS" == 'Debian' ];then
        . include/init_Debian.sh 2>&1 | tee $ScriptPath/logs/init_os.log
    elif [ "$OS" == 'Ubuntu' ];then
        . include/init_Ubuntu.sh 2>&1 | tee $ScriptPath/logs/init_os.log
    fi
    echo "${CMSG}[Initialization $OS OK please reboot] **************************************************>>${CEND}";
    SELECT_RUN_SCRIPT;
}
