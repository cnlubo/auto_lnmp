#!/bin/bash
###
# @Author: cnak47
# @Date: 2018-04-30 23:59:11
# @LastEditors: cnak47
# @LastEditTime: 2020-01-21 14:38:57
# @Description:
###

# shellcheck disable=SC2164
MariaDB_Var() {

    # 生成数据库root用户随机密码(8位长度包含字母数字和特殊字符)
    # shellcheck disable=SC2034
    dbrootpwd=$(openssl rand -base64 8)
    # shellcheck disable=SC2162
    read -p "Please input Port(Default:3306):" MysqlPort
    MysqlPort="${MysqlPort:=3306}"
    case $DbType in
    "MariaDB")
        {
            # shellcheck disable=SC2162
            read -p "Please input MySQL BaseDirectory(default:/u01/mariadb/$mariadb_install_version)" MysqlBasePath
            MysqlBasePath="${MysqlBasePath:=/u01/mariadb/$mariadb_install_version}"
        }
        ;;
    "MySql")
        {
            # shellcheck disable=SC2162
            read -p "Please input MySQL BaseDirectory(default:/u01/mysql/$mysql_install_version)" MysqlBasePath
            MysqlBasePath="${MysqlBasePath:=/u01/mysql/$mysql_install_version}"
        }
        ;;
    *)
        WARNING_MSG "unknow Dbtype"
        ;;
    esac
    if [ "$DbType" == 'MySql' ]; then
        # shellcheck disable=SC2162
        read -p "Please input MySQL Database Directory(default:/u01/mybase/my$MysqlPort/mysql/$mysql_install_version)" MysqlOptPath
        MysqlOptPath="${MysqlOptPath:=/u01/mybase/my$MysqlPort/mysql/$mysql_install_version}"
    elif [ "$DbType" == 'MariaDB' ]; then
        # shellcheck disable=SC2162
        read -p "Please input MySQL Database Directory(default:/u01/mybase/my$MysqlPort/mariadb/$mariadb_install_version)" MysqlOptPath
        MysqlOptPath="${MysqlOptPath:=/u01/mybase/my$MysqlPort/mariadb/$mariadb_install_version}"
    fi
    # shellcheck disable=SC2003
    # shellcheck disable=SC2154
    # shellcheck disable=SC2086
    def_innodb_buffer_pool_size=$(expr $RamTotal \* 80 / 102400)G
    # shellcheck disable=SC2162
    read -p "Please input innodb_buffer_pool_size (default:${def_innodb_buffer_pool_size})" innodb_buffer_pool_size
    innodb_buffer_pool_size="${innodb_buffer_pool_size:=$def_innodb_buffer_pool_size}"
    # 生成server_id
    HostIP=$(python "${script_dir:?}"/py2/get_local_ip.py)
    b=$(echo "${HostIP:?}" | cut -d\. -f2)
    c=$(echo "${HostIP:?}" | cut -d\. -f3)
    d=$(echo "${HostIP:?}" | cut -d\. -f4)
    pt=$(echo ${MysqlPort:?} % 256 | bc)
    # a=`echo ${HostIP:?}|cut -d\. -f1`
    # shellcheck disable=SC2003
    # shellcheck disable=SC2034
    server_id=$(expr "$b" \* 256 \* 256 \* 256 + "$c" \* 256 \* 256 + "$d" \* 256 + "$pt")
    #create group and user
    if ! grep "${mysql_user:?}" /etc/group >/dev/null 2>&1; then
        INFO_MSG "Create Mysql Group [$mysql_user]"
        groupadd "$mysql_user"
    fi
    if ! id "$mysql_user" >/dev/null 2>&1; then
        INFO_MSG "Create Mysql User [$mysql_user]"
        useradd -g "$mysql_user" -M -s /sbin/nologin "$mysql_user"
    fi
    # create dir
    INFO_MSG "Create Mysql related directorys ....."
    MysqlDataPath="${MysqlOptPath:?}/data"
    MysqlLogPath="$MysqlOptPath/log"
    MysqlConfigPath="$MysqlOptPath/etc"
    MysqlTmpPath="$MysqlOptPath/tmp"
    MysqlRunPath="$MysqlOptPath/run"
    for path in ${MysqlLogPath:?} ${MysqlConfigPath:?} ${MysqlDataPath:?} ${MysqlTmpPath:?} ${MysqlRunPath:?}; do
        [ -d "$path" ] && rm -rf "$path"
        mkdir -p "$path" && chmod 755 "$path" && chown -R "$mysql_user":"$mysql_user" "$path"
    done

}
MySQL_Base_Packages_Install() {

    INFO_MSG " remove old mysql and install BasePackages ....."
    case $OS in
    "CentOS")
        {
            yum -y remove mysql-server mysql
            if [ "$dbinstallmethod" == '2' ]; then
                BasePackages="wget gcc gcc-c++ autoconf libxml2-devel zlib-devel libjpeg-devel \
                    libpng-devel glibc-devel glibc-static glib2-devel  bzip2 bzip2-devel openssl-devel \
                    ncurses-devel bison cmake make libaio-devel expect gnutls-devel"
                if [ "$DbType" == 'MariaDB' ]; then
                    BasePackages=${BasePackages}" gnutls-devel"
                fi
            elif [ "$DbType" == 'MySql' ] && [ "$dbinstallmethod" == '1' ]; then
                BasePackages="libaio libnuma"
                OLDNCURSES_LIBS=$(rpm -qa | grep 'ncurses-libs' | head -n1)
                if [ -n "$OLDNCURSES_LIBS" ]; then
                    BasePackages=${BasePackages}" ncurses-libs"
                fi
            else
                echo ""
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
        WARNING_MSG "Not supported System !!! "
        ;;
    esac
    INSTALL_BASE_PACKAGES "$BasePackages"
    SOURCE_SCRIPT "${script_dir:?}"/include/jemalloc.sh
    Install_Jemalloc

    if [ "$DbType" == 'MySql' ] && [ "$DbVersion" == '5.7' ] && [ "$dbinstallmethod" == '2' ]; then
        # download boost 1.59.0
        # shellcheck disable=SC2034
        src_url=https://sourceforge.net/projects/boost/files/boost/1.59.0/boost_1_59_0.tar.gz
        cd "$script_dir"/src
        [ ! -f boost_1_59_0.tar.gz ] && Download_src
        [ -d boost_1_59_0 ] && rm -rf boost_1_59_0
        tar xf boost_1_59_0.tar.gz
        cd "$script_dir"
    fi

}
select_mariadb_install() {

    # system_check
    echo "${CMSG}-----------------------------------------------------------------------${CEND}"
    cat <<EOF
*  $(echo -e "$CMAGENTA  1) MySQL-${mysql_5_7_version:?} by binary package ")
*  $(echo -e "$CMAGENTA  2) MySQL-${mysql_5_7_version:?} by source code ")
*  $(echo -e "$CMAGENTA  3) MySQL-${mysql_8_0_version:?} by binary package ")
*  $(echo -e "$CMAGENTA  4) MySQL-${mysql_8_0_version:?} by source code    ")
*  $(echo -e "$CMAGENTA  5) MariaDB-${mariadb_10_2_version:?} by binary package ")
*  $(echo -e "$CMAGENTA  6) MariaDB-${mariadb_10_2_version:?} by source code ")
*  $(echo -e "$CMAGENTA  7) MariaDB-${mariadb_10_1_version:?} by binary package ")
*  $(echo -e "$CMAGENTA  8) MariaDB-${mariadb_10_1_version:?} by source code  ")
*  $(echo -e "$CMAGENTA  9) Back             ")
*  $(echo -e "$CMAGENTA  10) Quit             ")
EOF
    # shellcheck disable=SC2162
    read -p "${CBLUE}Which Version MySQL are you want to install:${CEND} " num3

    case $num3 in
    1)
        DbType="MySql"
        DbVersion="5.7"
        dbinstallmethod=1
        mysql_install_version=${mysql_5_7_version:?}
        SOURCE_SCRIPT "${FunctionPath:?}"/install/Mysql-5.7.sh
        MySQLDB_Install_Main 2>&1 | tee "$script_dir"/logs/Install_MySql5.7.log
        select_mysql_install
        ;;
    2)
        DbType="MySql"
        DbVersion="5.7"
        dbinstallmethod=2
        mysql_install_version=${mysql_5_7_version:?}
        SOURCE_SCRIPT "${FunctionPath:?}"/install/Mysql-5.7.sh
        MySQLDB_Install_Main 2>&1 | tee "$script_dir"/logs/Install_MySql5.7.log
        select_mysql_install
        ;;
    3)
        DbType="MySql"
        DbVersion="8.0"
        dbinstallmethod=1
        mysql_install_version=${mysql_8_0_version:?}
        SOURCE_SCRIPT "${FunctionPath:?}"/install/Mysql-8.0.sh
        MySQLDB_Install_Main 2>&1 | tee "$script_dir"/logs/Install_MySql8.0.log
        select_mysql_install
        ;;
    4)
        DbType="MySql"
        DbVersion="8.0"
        dbinstallmethod=2
        mysql_install_version=${mysql_8_0_version:?}
        SOURCE_SCRIPT "${FunctionPath:?}"/install/Mysql-8.0.sh
        MySQLDB_Install_Main 2>&1 | tee "$script_dir"/logs/Install_MySql8.0.log
        select_mysql_install
        ;;

    5)
        DbType="MariaDB"
        DbVersion="10.2"
        dbinstallmethod=1
        mariadb_install_version=${mariadb_10_2_version:?}
        SOURCE_SCRIPT "$FunctionPath"/install/MariaDB-10.2.sh
        MariaDB_10_2_Install_Main 2>&1 | tee "$script_dir"/logs/Install_MariaDB_10.2.log
        select_mysql_install
        ;;
    6)
        DbType="MariaDB"
        DbVersion="10.2"
        dbinstallmethod=2
        mariadb_install_version=${mariadb_10_2_version:?}
        SOURCE_SCRIPT "$FunctionPath"/install/MariaDB-10.2.sh
        MariaDB_10_2_Install_Main 2>&1 | tee "$script_dir"/logs/Install_MariaDB_10.2.log
        select_mysql_install
        ;;
    7)
        DbType="MariaDB"
        DbVersion="10.1"
        dbinstallmethod=1
        mariadb_install_version=${mariadb_10_2_version:?}
        SOURCE_SCRIPT "$FunctionPath"/install/MariaDB-10.1.sh
        MariaDB_10_1_Install_Main 2>&1 | tee "$script_dir"/logs/Install_MariaDB_10.1.log
        select_mysql_install
        ;;
    8)
        DbType="MariaDB"
        DbVersion="10.1"
        dbinstallmethod=2
        mariadb_install_version=${mariadb_10_2_version:?}
        SOURCE_SCRIPT "$FunctionPath"/install/MariaDB-10.1.sh
        MariaDB_10_1_Install_Main 2>&1 | tee "$script_dir"/logs/Install_MariaDB_10.1.log
        select_mysql_install
        ;;

    9)
        select_database_install
        ;;
    10)
        clear
        exit 0
        ;;
    *)
        select_mysql_install
        ;;
    esac
}
