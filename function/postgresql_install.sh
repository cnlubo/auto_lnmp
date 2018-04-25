#!/bin/bash
# shellcheck disable=SC2164
# shellcheck disable=SC2034
# ----------------------------------------------------------------
#@Author          :              cnlubo (454331202@qq.com)
#@Filename       :              postgresql_install.sh
#@desc           :               postgresql install main
#------------------------------------------------------------------
SOURCE_SCRIPT ${script_dir:?}/include/configure_os.sh
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
    # 使用默认非root 用户作为postgresql 运行用户
    id ${default_user:?} >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CWARNING}[ running user($default_user) exist !!!] *******************************>>${CEND}\n"
    else
        system_user_setup ${default_user:?}
    fi
    pgsql_user=${default_user:?}
    # create dir
    [ -d $PgsqlOptPath ] && rm -rf $PgsqlOptPath
    mkdir -p $PgsqlOptPath
    mkdir -p $PgsqlOptPath/data
    mkdir -p $PgsqlOptPath/run
    mkdir -p $PgsqlOptPath/archive
    mkdir -p $PgsqlOptPath/backup
    mkdir -p $PgsqlOptPath/logs
    chown -Rf $pgsql_user:$pgsql_user $PgsqlOptPath
}
PostgreSQL_Base_Packages_Install(){


    echo -e "${CMSG}[remove old PostgreSQL and install BasePackages] ***********>>${CEND}\n"
    case  $OS in
        "CentOS")
            {
                yum -y remove postgresql*
                # BasePackages="gcc glibc glibc-devel readline-devel zlib-devel libgcc  \
                    #     apr-devel flex-devel perl-ExtUtils-Embed tcl tcl-devel openldap openldap-devel \
                    #     libxml2 libxml2-devel pam pam-devel libxslt libxslt-devel openldap-devel"
                BasePackages="gcc glibc glibc-devel readline-devel libgcc  \
                    flex flex-devel perl-ExtUtils-Embed tcl tcl-devel openldap-devel \
                    pam-devel libxml2 libxml2-devel libxslt libxslt-devel"
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
    # 运行pgsql 的非root 用户
    system_user_setup ${default_user:?}
    # openssl
    SOURCE_SCRIPT ${script_dir:?}/include/openssl.sh
    Install_OpenSSL_Main  ${openssl_latest_version:?} ${openssl11_install_dir:?}
    # zlib
    zlib_install
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
            SOURCE_SCRIPT ${FunctionPath:?}/install/PostgreSQL-09.sh
            PostgreSQL_09_Install_Main 2>&1 | tee $script_dir/logs/Install_PostgreSQL09.log
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
