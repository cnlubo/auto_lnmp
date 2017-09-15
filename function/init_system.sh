#!/bin/bash
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              init_system.sh
# @Desc
#----------------------------------------------------------------------------
SOURCE_SCRIPT $script_dir/include/check_deps.sh
select_system_setup_function(){

    echo "${CMSG}[Initialization $OS] **************************************************>>${CEND}";

    case "${OS}" in
        "CentOS")
            installDepsCentOS 2>&1 | tee ${scriptPath}/logs/install.log
        ;;
        "Debian")
            installDepsDebian 2>&1 | tee ${scriptPath}/logs/install.log
        ;;
        "Ubuntu")
            installDepsUbuntu 2>&1 | tee ${scriptPath}//logs/install.log
        ;;
    esac
    # init
    #startTime=`date +%s`
    #. ./include/memory.sh
    case "${OS}" in
        "CentOS")

            $script_dir/include/init_centos.sh 2>&1 | tee -a ${scriptPath}/logs/install.log
        ;;
        "Debian")
            $script_dir/include/init_Debian.sh 2>&1 | tee -a ${scriptPath}/logs/install.log
        ;;
        "Ubuntu")
            $script_dir/include/init_Ubuntu.sh 2>&1 | tee -a ${scriptPath}/logs/install.log
        ;;
    esac

    echo "${CMSG}[Initialization $OS OK please reboot] **************************************************>>${CEND}";
    select_main_menu;
}
