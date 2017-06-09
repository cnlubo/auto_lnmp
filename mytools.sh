#!/bin/bash
#---------------------------------------------------------------------------
#
#   Author:                cnlubo (454331202@qq.com)
#   Date:                  2015-07-20 22:46:05
#   Filename:              mytools.sh
#   Desc:                  main  entry
#
#---------------------------------------------------------------------------
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
#get scriptpath
ScriptPath=$(cd $(dirname "$0") && pwd)
#sed -i "s@^script_dir.*@script_dir=`(cd $(dirname "$0") && pwd)`@" ./options.conf
sed -i "s@^script_dir.*@script_dir=`(cd $(dirname "$BASH_SOURCE[0]") && pwd)`@" ./options.conf
# mac 需要在sed -i 后增加一个"" 不能忽略否则报错
#sed -i "" "s@^script_dir.*@script_dir=`(cd $(dirname "$BASH_SOURCE[0]") && pwd)`@" ./options.conf
#加载配置内容
source $ScriptPath/include/color.sh
source $ScriptPath/include/common.sh
SOURCE_SCRIPT $ScriptPath/options.conf
SOURCE_SCRIPT $script_dir/apps.conf
SOURCE_SCRIPT $script_dir/include/check_os.sh
SOURCE_SCRIPT $script_dir/include/check_db.sh
SOURCE_SCRIPT $script_dir/include/check_web.sh
SOURCE_SCRIPT $script_dir/include/get_char.sh
SOURCE_SCRIPT $script_dir/include/memory.sh
clear;
printf "${CGREEN}
###############################################################################
# A tool to auto-compile & install  tomcat&&jdk&&nginx&&mysql&&redis          #
#                                                                             #
# Author:  lubo           project:  https://github.com/cnlubo/auto_lnmp       #
###############################################################################${CEND}
"
# Check if user is root
CHECK_ROOT
# get the IP information
IPADDR=`./py2/get_ipaddr.py`
PUBLIC_IPADDR=`./py2/get_public_ipaddr.py`
IPADDR_COUNTRY_ISP=`./py2/get_ipaddr_state.py $PUBLIC_IPADDR`
IPADDR_COUNTRY=`echo $IPADDR_COUNTRY_ISP | awk '{print $1}'`
[ "`echo $IPADDR_COUNTRY_ISP | awk '{print $2}'`"x == '1000323'x ] && IPADDR_ISP=aliyun
#echo $IPADDR_ISP
#main
SELECT_RUN_SCRIPT(){
    PS3="${CBLUE}Which function you want to run:${CEND}"
    VarLists=("Exit" "Init_System" "Tomcat" "nginx" "MySql" "redis")
    select var in ${VarLists[@]} ;do
        case $var in
            ${VarLists[1]})
                SOURCE_SCRIPT $FunctionPath/init_system.sh
            SELECT_SYSTEM_SETUP_FUNCTION;;
            ${VarLists[2]})
                SOURCE_SCRIPT $FunctionPath/tomcat_install.sh
            SELECT_TOMCAT_INSTALL;;
            ${VarLists[3]})
                SOURCE_SCRIPT $FunctionPath/tomcat_install.sh
            SELECT_TOMCAT_INSTALL;;
            ${VarLists[4]})
                SOURCE_SCRIPT $FunctionPath/mysql_install.sh
            SELECT_MYSQL_INSTALL;;
            ${VarLists[5]})
                SOURCE_SCRIPT $FunctionPath/tomcat_install.sh
            SELECT_TOMCAT_INSTALL;;
            ${VarLists[0]})
            exit 0;;
            *)
            SELECT_RUN_SCRIPT;;
        esac
        break
    done
    SELECT_RUN_SCRIPT
}
SELECT_RUN_SCRIPT
