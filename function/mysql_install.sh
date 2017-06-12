#!/bin/bash
# ----------------------------------------------------------------
#@Author         :              cnlubo (454331202@qq.com)
# @Date           :              2016-01-25 10:36:45
# @Filename       :              mysql_install.sh
# @desc           :              mysql install main
#------------------------------------------------------------------
SYSTEM_CHECK(){
    [[ "$OS" == '' ]] && echo "${CWARNING}[Error] Your system is not supported this script${CEND}" && exit;
    [ $RamTotalG -lt '1000' ] && echo -e "${CWARNING}[Error] Not enough memory install mysql.\nThis script need memory more than 1G.\n${CEND}" && SELECT_RUN_SCRIPT;
}

MySQL_Var(){

    while :
    do
        read -p "Please input the root password of database: " dbrootpwd
        (( ${#dbrootpwd} >= 5 )) &&dbrootpwd="${dbrootpwd:=""}"&& break || echo "${CWARNING}database root password least 5 characters! ${CEND}"
    done
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
        echo "unknow Dbtype";;
    esac
    read -p "Please input MySQL Database Directory(default:/u01/mybase/my$MysqlPort)" MysqlOptPath
    echo $MysqlBasePath
    MysqlOptPath="${MysqlOptPath:=/u01/mybase/my$MysqlPort}"
    MysqlDataPath="$MysqlOptPath/data"
    MysqlLogPath="$MysqlOptPath/log"
    MysqlConfigPath="$MysqlOptPath/etc"
    MysqlTmpPath="$MysqlOptPath/tmp"
    MysqlRunPath="$MysqlOptPath/run"
}
MYSQL_BASE_PACKAGES_INSTALL(){
    case  $OS in
        "CentOS")
            {
                echo '[remove old mysql] **************************************************>>';
                yum -y remove mysql-server mysql;
                BasePackages="wget gcc gcc-c++ autoconf libxml2-devel zlib-devel libjpeg-devel libpng-devel glibc-devel glibc-static glib2-devel  bzip2-devel openssl-devel ncurses-devel bison cmake make libaio-devel";
            }
        ;;
        "Ubuntu")
            {
                echo '[remove old mysql] **************************************************>>';
                apt-get -y remove mysql-client mysql-server mysql-common mariadb-server ;
                BasePackages="wget gcc g++ cmake libjpeg-dev libxml2 libxml2-dev libpng-dev autoconf make bison zlibc bzip2 libncurses5-dev libncurses5 libssl-dev axel libaio-dev";
            }
        ;;

        *)
        echo "not supported System";;
    esac
    echo $BasePackages
    INSTALL_BASE_PACKAGES $BasePackages

    if [ -f "/usr/local/lib/libjemalloc.so" ];then
        echo -e "\033[31mjemalloc having install! \033[0m"
    else
        #src_url=http://www.canonware.com/download/jemalloc/jemalloc-$jemalloc_version.tar.bz2
        #https://github.com/jemalloc/jemalloc/releases/download/4.3.1/jemalloc-4.3.1.tar.bz2
        src_url=https://github.com/jemalloc/jemalloc/releases/download/$jemalloc_version/jemalloc-$jemalloc_version.tar.bz2
        Download_src
        cd $script_dir/src
        tar xvf jemalloc-$jemalloc_version.tar.bz2
        cd jemalloc-$jemalloc_version
        ./configure
        make && make install
        if [ -f "/usr/local/lib/libjemalloc.so" ];then
            echo '/usr/local/lib' > /etc/ld.so.conf.d/local.conf
            ldconfig
        else
            echo -e "\033[31mjemalloc install failed, Please contact the author! \033[0m"
            kill -9 $$
        fi
        rm -rf jemalloc-$jemalloc_version
        cd $script_dir
    fi
    #下载boost 源码
    if [$DbType -eq "MySql" -a $DbVersion="5.7"];then
        src_url=https://sourceforge.net/projects/boost/files/boost/1.59.0/boost_1_59_0.tar.gz
        Download_src
        cd $script_dir/src
        tar xvf boost_1_59_0.tar.gz
        cd $script_dir
    fi
    #create group and user
    grep $mysql_user /etc/group >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        groupadd $mysql_user;
    fi
    id $mysql_user >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        useradd -g $mysql_user  -M -s /sbin/nologin $mysql_user;
    fi
    #create dir
    for path in $MysqlLogPath $MysqlConfigPath $MysqlDataPath $MysqlTmpPath $MysqlRunPath;do
        [ ! -d $path ] && mkdir -p $path
        chmod 755 $path;
        chown -R mysql:mysql $path;
    done
}
SELECT_MYSQL_INSTALL(){


    SYSTEM_CHECK
    echo "${CMSG}----------------------------------------------------------------------------------${CEND}"
    PS3="${CBLUE}Which version MySql are you want to install:${CEND}"
    declare -a VarLists
    VarLists=("Back" "MySQL-5.6" "MySQL-5.7" "MariaDB-10.1" "MariaDB-10.2")
    select var in ${VarLists[@]} ;do
        case $var in
            ${VarLists[1]})
                DbType="MySql"
                DbVersion="5.6"
                SOURCE_SCRIPT $FunctionPath/install/Mysql-5.6.sh
            MysqlDB_Install_Main;;
            ${VarLists[2]})
                DbType="MySql"
                DbVersion="5.7"
                SOURCE_SCRIPT $FunctionPath/install/Mysql-5.7.sh
            MysqlDB_Install_Main;;
            ${VarLists[3]})
                DbType="MariaDB"
                DbVersion="10.1"
                SOURCE_SCRIPT $FunctionPath/install/MariaDB-10.1.sh
            MariaDB_Install_Main;;
            ${VarLists[4]})
                DbType="MariaDB"
                DbVersion="10.2"
                SOURCE_SCRIPT $FunctionPath/install/MariaDB-10.2.sh
            MariaDB_Install_Main;;
            ${VarLists[0]})
            SELECT_RUN_SCRIPT;;
            *)
            SELECT_MYSQL_INSTALL;;
        esac
        break
    done
}
