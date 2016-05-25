#!/bin/bash
# ------------------------------------------------------------------------
# @Author:          cnlubo (454331202@qq.com)
# @Date:            2016-01-04 10:32:54
# @Filename:        tomcat_install.sh
# @desc    :        tomcat install
#--------------------------------------------------------------------------


SELECT_JDK_INSTALL(){
    while :
    do
        echo
        echo 'Please select JDK version:'
        echo -e "\t${CMSG}1${CEND}. Install JDK-1.8"
        echo -e "\t${CMSG}2${CEND}. Install JDK-1.7"
        echo -e "\t${CMSG}3${CEND}. Install JDK-1.6"
        read -p "Please input a number:(Default 2 press Enter) " JDK_version
        [ -z "$JDK_version" ] && JDK_version=2
        if [[ ! $JDK_version =~ ^[1-3]$ ]];then
            echo "${CWARNING}input error! Please only input number 1,2,3${CEND}"
        else
            break
        fi
    done

    if [ "$JDK_version" == '1' ];then
        SOURCE_SCRIPT $script_dir/include/jdk-1.8.sh
        Install-JDK-1-8 2>&1 | tee -a $script_dir/logs/install_jdk.log
    elif [ "$JDK_version" == '2' ];then
        SOURCE_SCRIPT $script_dir/include/jdk-1.7.sh
        Install-JDK-1-7 2>&1 | tee -a $script_dir/logs/install_jdk.log
    elif [ "$JDK_version" == '3' ];then
        $script_dir/include/jdk-1.6.sh
        Install-JDK-1-6 2>&1 | tee -a $script_dir/logs/install_jdk.log
    fi

}

SELECT_TOMCAT_INSTALL(){
    echo "----------------------------------------------------------------"
    declare -a VarLists
    echo "[Notice] Which version tomcat are you want to install:"
    VarLists=("Back" "tomcat7" "tomcat8")
    select var in ${VarLists[@]} ;do
        case $var in
            ${VarLists[1]})
                SOURCE_SCRIPT $FunctionPath/install/tomcat-7.sh
                SELECT_JDK_INSTALL
            Install_tomcat-7;;
            ${VarLists[2]})
                SOURCE_SCRIPT $FunctionPath/install/tomcat-8.sh
            TOMCAT_VAR && SELECT_TOMCAT_FUNCTION;;
            ${VarLists[0]})
            SELECT_RUN_SCRIPT;;
            *)
            SELECT_TOMCAT_INSTALL;;
        esac
        break
    done
}

