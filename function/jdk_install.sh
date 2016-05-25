#!/bin/bash
# -------------------------------------------
# @Date    : 2016-01-04 11:18:47
# @Author  : cnlubo (454331202@qq.com)
# @Version : 1.0
# @desc    : JDK install
#--------------------------------------------

SELECT_JDK_INSTALL(){
    echo "----------------------------------------------------------------"
    declare -a VarLists
    echo "[Notice] Which version JDK are you want to install:"
    VarLists=("Back" "JDK-1.7" "JDK-1.8")
    select var in ${VarLists[@]} ;do
        case $var in
            ${VarLists[1]})
                SOURCE_SCRIPT $FunctionPath/install/jdk-1.7.sh
                Install-JDK-1-7;;
            ${VarLists[2]})
                SOURCE_SCRIPT $FunctionPath/install/jdk-1.8.sh
                Install-JDK-1-8;;
            ${VarLists[0]})
                SELECT_RUN_SCRIPT;;
            *)
                SELECT_TOMCAT_INSTALL;;
        esac
        break
    done
}
