#!/bin/bash
# shellcheck disable=SC2164
# shellcheck disable=SC2034
# ----------------------------------------------------------------
#@Author          :              cnlubo (454331202@qq.com)
#@Filename       :              postgresql_install.sh
#@desc           :               postgresql install main
#------------------------------------------------------------------
system_check(){

    [[ "$OS" == '' ]] && echo "${CWARNING}[Error] Your system is not supported this script${CEND}" && exit
    [ ${RamTotal:?} -lt '1000' ] && echo -e "${CWARNING}[Error] Not enough memory install PostgreSQL.\nThis script need memory more than 1G.\n${CEND}" && exit
}

PostgreSQL_Var(){

    # # 检查是否存在运行的mysql进程
    # COUNT=$(ps aux|grep mysqld|grep -v grep |wc -l)
    # if [ $COUNT -gt 0 ]
    # then
    #     echo
    #     echo -e "${CWARNING}[Error MySQL is running please stop !!!!]${CEND}\n" && exit
    # fi
    # # 生成数据库root用户随机密码(8位长度包含字母数字和特殊字符)
    # # shellcheck disable=SC2034
    # dbrootpwd=`mkpasswd -l 8`
    # 安装目录
    read -p "Please input PostgreSQL BaseDirectory(default:/u01/pgsql/$postgresql_install_version)" PgsqlBasePath
    PgsqlBasePath="${PgsqlBasePath:=/u01/pgsql/$postgresql_install_version}"
    # 数据库目录
    read -p "Please input PostgreSQL Database Directory(default:/u01/pgbase/$postgresql_install_version)" PgsqlOptPath
    PgsqlOptPath="${PgsqlOptPath:=/u01/pgbase/$postgresql_install_version}"




}
PostgreSQL_Base_Packages_Install(){

    # echo -e "${CMSG}[remove old mysql and install BasePackages] *****************************>>${CEND}\n"
    # case  $OS in
    #     "CentOS")
    #         {
    #             yum -y remove mysql-server mysql
    #             BasePackages="wget gcc gcc-c++ autoconf libxml2-devel zlib-devel libjpeg-devel \
        #                 libpng-devel glibc-devel glibc-static glib2-devel  bzip2 bzip2-devel openssl-devel \
        #                 ncurses-devel bison cmake make libaio-devel expect gnutls-devel"
    #             if [ $DbType == 'MariaDB' ];then
    #                 BasePackages=${BasePackages}" gnutls-devel"
    #             fi
    #         }
    #         ;;
    #     "Ubuntu")
    #         {
    #             apt-get -y remove mysql-client mysql-server mysql-common mariadb-server
    #             BasePackages="wget gcc g++ cmake libjpeg-dev libxml2 libxml2-dev libpng-dev \
        #                 autoconf make bison zlibc bzip2 libncurses5-dev libncurses5 libssl-dev axel libaio-dev"
    #         }
    #         ;;
    #
    #     *)
    #         echo -e "${CMSG}[ not supported System !!! ] ***********************>>${CEND}\n"
    #         ;;
    # esac
    # INSTALL_BASE_PACKAGES $BasePackages
    # SOURCE_SCRIPT ${script_dir:?}/include/jemalloc.sh
    # Install_Jemalloc
    # #下载boost 源码
    # if [ $DbType == 'MySql' ] && [ $DbVersion == '5.7' ];then
    #     # shellcheck disable=SC2034
    #     src_url=https://sourceforge.net/projects/boost/files/boost/1.59.0/boost_1_59_0.tar.gz
    #     cd $script_dir/src
    #     [ ! -f boost_1_59_0.tar.gz ] && Download_src
    #     [ -d boost_1_59_0 ] && rm -rf boost_1_59_0
    #     tar xf boost_1_59_0.tar.gz
    #     cd $script_dir
    # fi
    # #create group and user
    # grep ${mysql_user:?} /etc/group >/dev/null 2>&1
    # if [ ! $? -eq 0 ]; then
    #     groupadd $mysql_user;
    # fi
    # id $mysql_user >/dev/null 2>&1
    # if [ ! $? -eq 0 ]; then
    #     useradd -g $mysql_user  -M -s /sbin/nologin $mysql_user
    # fi

    echo -e "${CMSG}[remove old PostgreSQL and install BasePackages] ***********>>${CEND}\n"
    case  $OS in
        "CentOS")
            {
                yum -y remove postgresql*
                BasePackages="gcc glibc glibc-devel readline-devel zlib-devel libgcc  \
                    apr-devel flex-devel perl-ExtUtils-Embed"
            }
            ;;
        "Ubuntu")
            {
                echo  ""
            }
            ;;

        *)
            echo -e "${CMSG}[ not supported System !!! ] ***********************>>${CEND}\n"
            ;;
    esac
    INSTALL_BASE_PACKAGES $BasePackages
}
select_postgresql_install(){

    system_check
    echo "${CMSG}-----------------------------------------------------------------------${CEND}"
    cat << EOF
*  `echo -e "$CBLUE  1) PostgreSQL-${PostgreSQL_10_version:?}        "`
*  `echo -e "$CBLUE  2) PostgreSQL-${PostgreSQL_9_version:?}        "`
*  `echo -e "$CBLUE  3) Back             "`
*  `echo -e "$CBLUE  4) Quit             "`
EOF
    read -p "${CBLUE}Which Version PostgreSQL are you want to install:${CEND} " num3

    case $num3 in
        1)
            DbType="PostgreSQL"
            DbVersion="10"
            postgresql_install_version=${PostgreSQL_10_version:?}
            SOURCE_SCRIPT ${FunctionPath:?}/install/PostgreSQL-10.sh
            PostgreSQL_10_Install_Main 2>&1 | tee $script_dir/logs/Install_PostgreSQL10.log
            select_postgresql_install
            ;;
        2)
            DbType="PostgreSQL"
            DbVersion="9"
            postgresql_install_version=${PostgreSQL_9_version:?}
            #SOURCE_SCRIPT ${FunctionPath:?}/install/Mysql-5.7.sh
            #MySQLDB_Install_Main 2>&1 | tee $script_dir/logs/Install_MySql5.7.log
            select_postgresql_install
            ;;
        3)
            clear
            select_main_menu
            ;;
        4)
            clear
            exit 0
            ;;
        *)
            select_postgresql_install
    esac
}
