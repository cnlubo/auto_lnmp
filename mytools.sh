#!/bin/bash
#---------------------------------------------------------------------------
#
#   Author:                cnlubo (454331202@qq.com)
#   Filename:              mytools.sh
#   Desc:                  main  entry
#
#---------------------------------------------------------------------------
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
# dirname $0，取得当前执行的脚本文件的父目录
# cd `dirname $0`，进入这个目录(切换当前工作目录)
# pwd，显示当前工作目录(cd执行后的)
parentdir=$(dirname "$0")
ScriptPath=$(cd ${parentdir:?} && pwd)
# BASH_SOURCE[0] 等价于 BASH_SOURCE,取得当前执行的shell文件所在的路径及文件名
scriptdir=$(dirname "${BASH_SOURCE[0]}")
#sed -i "s@^script_dir.*@script_dir=`(cd ${scriptdir:?} && pwd)`@" ./options.conf
sed -i "s@^script_dir.*@script_dir=`(cd ${scriptdir:?} && pwd)`@" ./config/common.conf

# mac 需要在sed -i 后增加一个"" 不能忽略否则报错
#sed -i "" "s@^script_dir.*@script_dir=`(cd $(dirname "$BASH_SOURCE[0]") && pwd)`@" ./options.conf
#加载配置内容
# shellcheck source=$ScriptPath/include/color.sh
source $ScriptPath/include/color.sh
# shellcheck source=$ScriptPath/include/common.sh
source $ScriptPath/include/common.sh
SOURCE_SCRIPT $ScriptPath/config/common.conf
SOURCE_SCRIPT ${script_dir:?}/options.conf
SOURCE_SCRIPT ${script_dir:?}/apps.conf
SOURCE_SCRIPT $script_dir/include/check_os.sh
SOURCE_SCRIPT $script_dir/include/set_dir.sh
SOURCE_SCRIPT $script_dir/include/set_menu.sh
# SOURCE_SCRIPT $script_dir/include/memory.sh
# Check if user is root
[[ $(id -u) != '0' ]] && EXIT_MSG "Please use root to run this script."
## get the IP information
#IPADDR=`./py2/get_ipaddr.py`
#PUBLIC_IPADDR=`./py2/get_public_ipaddr.py`
#IPADDR_COUNTRY_ISP=`./py2/get_ipaddr_state.py $PUBLIC_IPADDR`
#IPADDR_COUNTRY=`echo $IPADDR_COUNTRY_ISP | awk '{print $1}'`
#[ "`echo $IPADDR_COUNTRY_ISP | awk '{print $2}'`"x == '1000323'x ] && IPADDR_ISP=aliyun

select_main_menu(){
    main_menu
    while true ;do
        read -p "${CBLUE}Which function you want to run:${CEND}" num1
        case $num1 in
            1)
                SOURCE_SCRIPT ${FunctionPath:?}/init_system.sh
                select_system_setup_function
                ;;
            2)
                SOURCE_SCRIPT $FunctionPath/database_install.sh
                select_database_install
                ;;
            3)
                SOURCE_SCRIPT $FunctionPath/web_install.sh
                select_web_install
                ;;
            4)
                SOURCE_SCRIPT $FunctionPath/devopstools_install.sh
                select_devops_install
                ;;
            5)
                clear
                exit 0
                ;;
            *)
                clear
                select_main_menu
        esac
    done
}

select_main_menu
