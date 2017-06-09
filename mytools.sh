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
#IPADDR=`./py2/get_ipaddr.py`
#PUBLIC_IPADDR=`./py2/get_public_ipaddr.py`
#[ "`./py2/get_ipaddr_state.py $PUBLIC_IPADDR`" == '\u4e2d\u56fd' ] && IPADDR_STATE=CN

# Use default SSH port 22. If you use another SSH port on your server
# if [ -e "/etc/ssh/sshd_config" ];then
#     [ -z "`grep ^Port /etc/ssh/sshd_config`" ] && ssh_port=22 || ssh_port=`grep ^Port /etc/ssh/sshd_config | awk '{print $2}'`
#     while :
#     do
#         echo
#         read -p "Please input SSH port(Default: $ssh_port): " SSH_PORT
#         [ -z "$SSH_PORT" ] && SSH_PORT=$ssh_port
#         if [ $SSH_PORT -eq 22 >/dev/null 2>&1 -o $SSH_PORT -gt 1024 >/dev/null 2>&1 -a $SSH_PORT -lt 65535 >/dev/null 2>&1 ];then
#             break
#         else
#             echo "${CWARNING}input error! Input range: 22,1025~65534${CEND}"
#         fi
#     done

#     if [ -z "`grep ^Port /etc/ssh/sshd_config`" -a "$SSH_PORT" != '22' ];then
#         sed -i "s@^#Port.*@&\nPort $SSH_PORT@" /etc/ssh/sshd_config
#     elif [ -n "`grep ^Port /etc/ssh/sshd_config`" ];then
#         sed -i "s@^Port.*@Port $SSH_PORT@" /etc/ssh/sshd_config
#     fi
# fi
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
