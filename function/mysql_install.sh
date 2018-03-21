#!/bin/bash
# shellcheck disable=SC2164
# ----------------------------------------------------------------
#@Author          :              cnlubo (454331202@qq.com)
#@Filename       :              mysql_install.sh
#@desc           :              mysql install main
#------------------------------------------------------------------
system_check(){

    # 检查是否存在运行的mysql进程
    #PIDCHECK=`ps aux|grep mysqld|grep -v grep`
    #PID="$?"
    COUNT=$(ps aux|grep mysqld|grep -v grep |wc -l)
    if [ $COUNT -gt 0 ]
    then
        echo -e "${CWARNING}[Error MySQL is running please stop !!!!]${CEND}\n" && select_main_menu
    fi

    # 检查其它信息
    [[ "$OS" == '' ]] && echo "${CWARNING}[Error] Your system is not supported this script${CEND}" && select_main_menu
    [ ${RamTotalG:?} -lt '1000' ] && echo -e "${CWARNING}[Error] Not enough memory install mysql.\nThis script need memory more than 1G.\n${CEND}" && select_main_menu
}

MySQL_Var(){

    # 生成数据库root用户随机密码(8位长度包含字母数字和特殊字符)
    # shellcheck disable=SC2034
    dbrootpwd=`mkpasswd -l 8`
    read -p "Please input Port(Default:3306):" MysqlPort
    MysqlPort="${MysqlPort:=3306}"
    case   $DbType in
        "MariaDB")
            {
                read -p "Please input MySQL BaseDirectory(default:/u01/MariaDB)" MysqlBasePath
                MysqlBasePath="${MysqlBasePath:=/u01/MariaDB}"
            }
            ;;
        "MySql")
            {
                read -p "Please input MySQL BaseDirectory(default:/u01/Mysql)" MysqlBasePath
                MysqlBasePath="${MysqlBasePath:=/u01/Mysql}"
            }
            ;;
        *)
            echo "unknow Dbtype" ;;
    esac
    read -p "Please input MySQL Database Directory(default:/u01/mybase/my$MysqlPort)" MysqlOptPath
    MysqlOptPath="${MysqlOptPath:=/u01/mybase/my$MysqlPort}"
    innodb_buffer_pool_size=`expr $RamTotalG \* 50 / 102400`
    read -p "Please input innodb_buffer_pool_size (default:${innodb_buffer_pool_size}G)" innodb_buffer_pool_size
    # 生成server_id
    HostIP=`python ${script_dir:?}/py2/get_local_ip.py`
    # a=`echo ${HostIP:?}|cut -d\. -f1`
    b=`echo ${HostIP:?}|cut -d\. -f2`
    c=`echo ${HostIP:?}|cut -d\. -f3`
    d=`echo ${HostIP:?}|cut -d\. -f4`
    pt=`echo ${MysqlPort:?} % 256 | bc`
    # shellcheck disable=SC2034
    server_id=`expr $b \* 256 \* 256 \* 256 + $c \* 256 \* 256 + $d \* 256 + $pt`
    # create dir
    MysqlDataPath="${MysqlOptPath:?}/data"
    MysqlLogPath="$MysqlOptPath/log"
    MysqlConfigPath="$MysqlOptPath/etc"
    MysqlTmpPath="$MysqlOptPath/tmp"
    MysqlRunPath="$MysqlOptPath/run"
    for path in ${MysqlLogPath:?} ${MysqlConfigPath:?} ${MysqlDataPath:?} ${MysqlTmpPath:?} ${MysqlRunPath:?};do
        # [ ! -d $path ] && mkdir -p $path
        [ -d ${parh:?} ] && rm -rf ${parh:?}
        mkdir -p $path && chmod 755 $path && chown -R mysql:mysql $path
    done

}
MySQL_Base_Packages_Install(){

    echo -e "${CMSG}[remove old mysql and install BasePackages] *****************************>>${CEND}\n"
    case  $OS in
        "CentOS")
            {
                yum -y remove mysql-server mysql
                BasePackages="wget gcc gcc-c++ autoconf libxml2-devel zlib-devel libjpeg-devel \
                    libpng-devel glibc-devel glibc-static glib2-devel  bzip2 bzip2-devel openssl-devel \
                    ncurses-devel bison cmake make libaio-devel expect gnutls-devel"
                if [ $DbType == 'MariaDB' ];then
                    BasePackages=${BasePackages}" gnutls-devel"
                fi
            }
            ;;
        "Ubuntu")
            {
                apt-get -y remove mysql-client mysql-server mysql-common mariadb-server
                BasePackages="wget gcc g++ cmake libjpeg-dev libxml2 libxml2-dev libpng-dev \
                    autoconf make bison zlibc bzip2 libncurses5-dev libncurses5 libssl-dev axel libaio-dev"
            }
            ;;

        *)
            echo -e "${CMSG}[ not supported System !!! ] ***********************>>${CEND}\n"
            ;;
    esac
    INSTALL_BASE_PACKAGES $BasePackages
    SOURCE_SCRIPT ${script_dir:?}/include/jemalloc.sh
    Install_Jemalloc
    #下载boost 源码
    if [ $DbType == 'MySql' ] && [ $DbVersion == '5.7' ];then
        # shellcheck disable=SC2034
        src_url=https://sourceforge.net/projects/boost/files/boost/1.59.0/boost_1_59_0.tar.gz
        cd $script_dir/src
        [ ! -f boost_1_59_0.tar.gz ] && Download_src
        [ -d boost_1_59_0 ] && rm -rf boost_1_59_0
        tar xvf boost_1_59_0.tar.gz
        cd $script_dir
    fi
    #create group and user
    grep ${mysql_user:?} /etc/group >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        groupadd $mysql_user;
    fi
    id $mysql_user >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        useradd -g $mysql_user  -M -s /sbin/nologin $mysql_user
    fi
}
select_mysql_install(){

    system_check
    echo "${CMSG}-----------------------------------------------------------------------${CEND}"
    cat << EOF
*  `echo -e "$CBLUE  1) MySQL-5.7        "`
*  `echo -e "$CBLUE  2) MariaDB-10.2     "`
*  `echo -e "$CBLUE  3) MariaDB-10.1     "`
*  `echo -e "$CBLUE  4) Back             "`
*  `echo -e "$CBLUE  5) Quit             "`
EOF
    read -p "${CBLUE}Which Version MySQL are you want to install:${CEND} " num3

    case $num3 in
        1)
            DbType="MySql"
            DbVersion="5.7"
            SOURCE_SCRIPT ${FunctionPath:?}/install/Mysql-5.7.sh
            MySQLDB_Install_Main 2>&1 | tee $script_dir/logs/Install_MySql5.7.log
            select_mysql_install
            ;;
        2)
            DbType="MariaDB"
            DbVersion="10.2"
            SOURCE_SCRIPT $FunctionPath/install/MariaDB-10.2.sh
            MariaDB_10_2_Install_Main 2>&1 | tee $script_dir/logs/Install_MariaDB_10.2.log
            select_mysql_install
            ;;
        3)
            DbType="MariaDB"
            DbVersion="10.1"
            SOURCE_SCRIPT $FunctionPath/install/MariaDB-10.1.sh
            MariaDB_10_2_Install_Main 2>&1 | tee $script_dir/logs/Install_MariaDB_10.1.log
            select_mysql_install
            ;;
        4)
            clear
            select_main_menu
            ;;
        5)
            clear
            exit 0
            ;;
        *)
            select_mysql_install
    esac
}
