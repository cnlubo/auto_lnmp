#!/bin/bash
# shellcheck disable=SC2164
# ----------------------------------------------------------------
#@Author          :              cnlubo (454331202@qq.com)
#@Filename       :              mysql_install.sh
#@desc           :              mysql install main
#------------------------------------------------------------------
system_check(){

    [[ "$OS" == '' ]] && echo "${CWARNING}[Error] Your system is not supported this script${CEND}" && exit
    [ ${RamTotal:?} -lt '1000' ] && echo -e "${CWARNING}[Error] Not enough memory install mySQL.\nThis script need memory more than 1G.\n${CEND}" && exit
}

MySQL_Var(){

    # 检查是否存在运行的mysql进程
    COUNT=$(ps aux|grep mysqld|grep -v grep |wc -l)
    if [ $COUNT -gt 0 ]
    then
        echo
        echo -e "${CWARNING}[Error MySQL is running please stop !!!!]${CEND}\n" && exit
    fi
    # 生成数据库root用户随机密码(8位长度包含字母数字和特殊字符)
    # shellcheck disable=SC2034
    dbrootpwd=`mkpasswd -l 8`
    read -p "Please input Port(Default:3306):" MysqlPort
    MysqlPort="${MysqlPort:=3306}"
    case   $DbType in
        "MariaDB")
            {
                if [ $DbVersion == '10.2' ] || [ $DbVersion == '10.1' ];then
                    read -p "Please input MySQL BaseDirectory(default:/u01/mariadb/$mariadb_install_version)" MysqlBasePath
                    MysqlBasePath="${MysqlBasePath:=/u01/mariadb/$mariadb_install_version}"
                else
                    ead -p "Please input MySQL BaseDirectory(default:/u01/mariadb)" MysqlBasePath
                    MysqlBasePath="${MysqlBasePath:=/u01/mariadb}"
                fi
            }
            ;;
        "MySql")
            {
                if [ $DbVersion == '5.7' ];then
                    read -p "Please input MySQL BaseDirectory(default:/u01/mysql/$mysql_install_version)" MysqlBasePath
                    MysqlBasePath="${MysqlBasePath:=/u01/mysql/$mysql_install_version}"
                else
                    ead -p "Please input MySQL BaseDirectory(default:/u01/mysql)" MysqlBasePath
                    MysqlBasePath="${MysqlBasePath:=/u01/mysql}"
                fi
            }
            ;;
        *)
            echo "unknow Dbtype" ;;
    esac
    if [ $DbType == 'MySql' ];then
        read -p "Please input MySQL Database Directory(default:/u01/mybase/my$MysqlPort/mysql/$mysql_install_version)" MysqlOptPath
        MysqlOptPath="${MysqlOptPath:=/u01/mybase/my$MysqlPort/mysql/$mysql_install_version}"
    elif [ $DbType == 'MariaDB' ];then
        read -p "Please input MySQL Database Directory(default:/u01/mybase/my$MysqlPort/mariadb/$mariadb_install_version)" MysqlOptPath
        MysqlOptPath="${MysqlOptPath:=/u01/mybase/my$MysqlPort/mariadb/$mariadb_install_version}"
    else
        read -p "Please input MySQL Database Directory(default:/u01/mybase/my$MysqlPort)" MysqlOptPath
        MysqlOptPath="${MysqlOptPath:=/u01/mybase/my$MysqlPort}"
    fi
    def_innodb_buffer_pool_size=`expr $RamTotal \* 80 / 102400`G
    read -p "Please input innodb_buffer_pool_size (default:${def_innodb_buffer_pool_size})" innodb_buffer_pool_size
    innodb_buffer_pool_size="${innodb_buffer_pool_size:=$def_innodb_buffer_pool_size}"
    # 生成server_id
    HostIP=`python ${script_dir:?}/py2/get_local_ip.py`
    b=`echo ${HostIP:?}|cut -d\. -f2`
    c=`echo ${HostIP:?}|cut -d\. -f3`
    d=`echo ${HostIP:?}|cut -d\. -f4`
    pt=`echo ${MysqlPort:?} % 256 | bc`
    # a=`echo ${HostIP:?}|cut -d\. -f1`
    # shellcheck disable=SC2034
    server_id=`expr $b \* 256 \* 256 \* 256 + $c \* 256 \* 256 + $d \* 256 + $pt`
    #create group and user
    grep ${mysql_user:?} /etc/group >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        groupadd $mysql_user;
    fi
    id $mysql_user >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        useradd -g $mysql_user  -M -s /sbin/nologin $mysql_user
    fi
    # create dir
    MysqlDataPath="${MysqlOptPath:?}/data"
    MysqlLogPath="$MysqlOptPath/log"
    MysqlConfigPath="$MysqlOptPath/etc"
    MysqlTmpPath="$MysqlOptPath/tmp"
    MysqlRunPath="$MysqlOptPath/run"
    for path in ${MysqlLogPath:?} ${MysqlConfigPath:?} ${MysqlDataPath:?} ${MysqlTmpPath:?} ${MysqlRunPath:?};do
        [ -d $path ] && rm -rf $path
        mkdir -p $path && chmod 755 $path && chown -R $mysql_user:$mysql_user $path
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
        tar xf boost_1_59_0.tar.gz
        cd $script_dir
    fi

}
select_mysql_install(){

    system_check
    echo "${CMSG}-----------------------------------------------------------------------${CEND}"
    cat << EOF
*  `echo -e "$CBLUE  1) MySQL-${mysql_5_7_version:?}        "`
*  `echo -e "$CBLUE  2) MariaDB-${mariadb_10_2_version:?}   "`
*  `echo -e "$CBLUE  3) MariaDB-${mariadb_10_1_version:?}   "`
*  `echo -e "$CBLUE  4) Back             "`
*  `echo -e "$CBLUE  5) Quit             "`
EOF
    read -p "${CBLUE}Which Version MySQL are you want to install:${CEND} " num3

    case $num3 in
        1)
            DbType="MySql"
            DbVersion="5.7"
            mysql_install_version=${mysql_5_7_version:?}
            SOURCE_SCRIPT ${FunctionPath:?}/install/Mysql-5.7.sh
            MySQLDB_Install_Main 2>&1 | tee $script_dir/logs/Install_MySql5.7.log
            select_mysql_install
            ;;
        2)
            DbType="MariaDB"
            DbVersion="10.2"
            mariadb_install_version=${mariadb_10_2_version:?}
            SOURCE_SCRIPT $FunctionPath/install/MariaDB-10.2.sh
            MariaDB_10_2_Install_Main 2>&1 | tee $script_dir/logs/Install_MariaDB_10.2.log
            select_mysql_install
            ;;
        3)
            DbType="MariaDB"
            DbVersion="10.1"
            mariadb_install_version=${mariadb_10_2_version:?}
            SOURCE_SCRIPT $FunctionPath/install/MariaDB-10.1.sh
            MariaDB_10_1_Install_Main 2>&1 | tee $script_dir/logs/Install_MariaDB_10.1.log
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
