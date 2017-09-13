#!/bin/bash
#---------------------------------------------------------------------------
#
#   Author:                cnlubo (454331202@qq.com)
#   Filename:              mytools.sh
#   Desc:                  main  entry
#
#---------------------------------------------------------------------------
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
#get scriptpath
ScriptPath=$(cd $(dirname "$0") && pwd)
sed -i "s@^script_dir.*@script_dir=`(cd $(dirname "$BASH_SOURCE[0]") && pwd)`@" ./options.conf
# mac 需要在sed -i 后增加一个"" 不能忽略否则报错
#sed -i "" "s@^script_dir.*@script_dir=`(cd $(dirname "$BASH_SOURCE[0]") && pwd)`@" ./options.conf
#加载配置内容
source $ScriptPath/include/color.sh
source $ScriptPath/include/common.sh
SOURCE_SCRIPT $ScriptPath/options.conf
SOURCE_SCRIPT $script_dir/apps.conf
SOURCE_SCRIPT $script_dir/include/check_os.sh
SOURCE_SCRIPT $script_dir/include/set_dir.sh
SOURCE_SCRIPT $script_dir/include/set_menu.sh
# SOURCE_SCRIPT $script_dir/include/memory.sh
#clear;
# Check if user is root
[[ $(id -u) != '0' ]] && EXIT_MSG "Please use root to run this script."

# modify ssh port 

#if [ -e "/etc/ssh/sshd_config" ]; then
#    [ -z "`grep ^Port /etc/ssh/sshd_config`" ] && ssh_port=22 || ssh_port=`grep ^Port /etc/ssh/sshd_config | awk '{print $2}'`
#    while :; do echo
#        read -p "Please input SSH port(Default: $ssh_port): " SSH_PORT
#        [ -z "$SSH_PORT" ] && SSH_PORT=$ssh_port
#        if [ $SSH_PORT -eq 22 >/dev/null 2>&1 -o $SSH_PORT -gt 1024 >/dev/null 2>&1 -a $SSH_PORT -lt 65535 >/dev/null 2>&1 ]; then
#            break
#        else
#            echo "${CWARNING}input error! Input range: 22,1025~65534${CEND}"
#        fi
#    done
#
#    if [ -z "`grep ^Port /etc/ssh/sshd_config`" -a "$SSH_PORT" != '22' ]; then
#        sed -i "s@^#Port.*@&\nPort $SSH_PORT@" /etc/ssh/sshd_config
#    elif [ -n "`grep ^Port /etc/ssh/sshd_config`" ]; then
#        sed -i "s@^Port.*@Port $SSH_PORT@" /etc/ssh/sshd_config
#    fi
#fi
# get the IP information
IPADDR=`./py2/get_ipaddr.py`
PUBLIC_IPADDR=`./py2/get_public_ipaddr.py`
IPADDR_COUNTRY_ISP=`./py2/get_ipaddr_state.py $PUBLIC_IPADDR`
IPADDR_COUNTRY=`echo $IPADDR_COUNTRY_ISP | awk '{print $1}'`
[ "`echo $IPADDR_COUNTRY_ISP | awk '{print $2}'`"x == '1000323'x ] && IPADDR_ISP=aliyun
clear;
printf "${CGREEN}
######################################################################
# A tool to auto-compile & install tomcat&&jdk&&nginx&&mysql&&redis  #
#                                                                    #
# Author:  lubo  project:  https://github.com/cnlubo/auto_lnmp       #
#####################################################################${CEND}
"
#echo -e "\n"
#main_menu
#
while true ;do
 read -p "##please Enter Your Choice:[1-6]" num1
 expr $num1 + 1 &>/dev/null   #这里加1，判断输入的是不是整数。

# if [ $? -ne 0 ];then   #如果不等于零，代表输入不是整数。
#    echo "----------------------------"
#    echo "|      Waring!!!           |"
#    echo "|Please Enter Right Choice!|"
#    echo "----------------------------"
#    sleep 1
#  fi

   case $num1 in
      1)
       clear
       main_menu
       ;;
      2)
       clear
       main_menu
       ;;
      3)
       clear
       main_menu
       ;;
      4)
       clear
       main_menu
       ;;
      5)
       clear
       main_menu
       ;;
      6)
       clear
       break
       ;;
      *)
      main_menu
   esac
done


SELECT_RUN_SCRIPT(){
    PS3="${CBLUE}Which function you want to run:${CEND}"
    VarLists=("init_system" "nginx" "tomcat" "mysql" "postgresql" "redis" "exit_system")
    select var in ${VarLists[@]} ;do
        case $var in
            ${VarLists[1]})
                SOURCE_SCRIPT $FunctionPath/init_system.sh
                SELECT_SYSTEM_SETUP_FUNCTION;;
            ${VarLists[2]})
                SOURCE_SCRIPT $FunctionPath/tomcat_install.sh
                SELECT_TOMCAT_INSTALL;;
            ${VarLists[3]})
                SOURCE_SCRIPT $FunctionPath/mysql_install.sh
                SELECT_MYSQL_INSTALL;;
            # ${VarLists[4]})
                #     SOURCE_SCRIPT $FunctionPath/mysql_install.sh
                # SELECT_MYSQL_INSTALL;;
            # ${VarLists[5]})
                #     SOURCE_SCRIPT $FunctionPath/tomcat_install.sh
                # SELECT_TOMCAT_INSTALL;;
            ${VarLists[6]})
                exit 0;;
            *)
                SELECT_RUN_SCRIPT;;
        esac
        break
    done
    SELECT_RUN_SCRIPT
}
# SELECT_RUN_SCRIPT
