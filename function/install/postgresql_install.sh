#!/bin/bash
###
# @Author: cnak47
# @Date: 2018-04-30 23:59:11
# @LastEditors: cnak47
# @LastEditTime: 2021-02-13 10:17:56
# @Description:
###

PostgreSQL_Var() {

    if check_app_status "postgreSQL"; then
        WARNING_MSG "[PostgreSQL is running please stop !!!!]" && exit 0
    fi
    # install directory
    # shellcheck disable=SC2162
    read -p "Please input PostgreSQL BaseDirectory(default:/u01/pgsql/$postgresql_install_version)" PgsqlBasePath
    PgsqlBasePath="${PgsqlBasePath:=/u01/pgsql/$postgresql_install_version}"
    # 数据库目录
    # shellcheck disable=SC2162
    read -p "Please input PostgreSQL Database Directory(default:/u01/pgbase/$postgresql_install_version)" PgsqlOptPath
    PgsqlOptPath="${PgsqlOptPath:=/u01/pgbase/$postgresql_install_version}"
    PgsqlDataPath=$PgsqlOptPath/data
    # 使用默认非root 用户作为postgresql 运行用户
    id "${default_user:?}" >/dev/null 2>&1
    if id "${default_user:?}" >/dev/null 2>&1; then
        WARNING_MSG "running user($default_user) exist !!!"
    else
        system_user_setup "${default_user:?}"
    fi
    pgsql_user=${default_user:?}
    # create dir
    [ -d "$PgsqlOptPath" ] && rm -rf "$PgsqlOptPath"
    mkdir -p "$PgsqlOptPath"
    [ -d "$PgsqlDataPath" ] && rm -rf "$PgsqlDataPath"
    mkdir -p "$PgsqlDataPath"
    mkdir -p "$PgsqlOptPath"/run
    mkdir -p "$PgsqlOptPath"/archive
    mkdir -p "$PgsqlOptPath"/backup
    mkdir -p "$PgsqlOptPath"/logs
    chown -Rf "$pgsql_user":"$pgsql_user" "$PgsqlOptPath"
}
PostgreSQL_Base_Packages_Install() {

    INFO_MSG "remove old PostgreSQL and install BasePackages !!!!"
    case $OS in
    "CentOS")
        {
            yum -y remove postgresql*
            BasePackages="gcc glibc glibc-devel readline-devel libgcc  \
                    flex flex-devel perl-ExtUtils-Embed tcl tcl-devel openldap-devel \
                    pam-devel libxml2 libxml2-devel libxslt libxslt-devel"
        }
        ;;
    "Ubuntu")
        {
            echo ""
        }
        ;;

    *)
        WARNING_MSG ""
        ;;
    esac
    # shellcheck disable=SC2086
    INSTALL_BASE_PACKAGES $BasePackages
    # 运行pgsql 的非root 用户
    # shellcheck disable=SC2086
    system_user_setup ${default_user:?}
    # openssl
    SOURCE_SCRIPT "${script_dir:?}"/include/openssl.sh
    Install_OpenSSL_Main "${openssl_latest_version:?}" "${openssl11_install_dir:?}"
    # zlib
    zlib_install
}
select_postgresql_install() {

    # system_check
    echo "${CMSG}-----------------------------------------------------------------------${CEND}"
    cat <<EOF
*  $(echo -e "$CMAGENTA  1) PostgreSQL-${PostgreSQL_13_version:?}        ")
*  $(echo -e "$CMAGENTA  2) PostgreSQL-${PostgreSQL_12_version:?}        ")
*  $(echo -e "$CMAGENTA  3) Back             ")
*  $(echo -e "$CMAGENTA  4) Quit             ")
EOF
    # shellcheck disable=SC2162
    read -p "${CBLUE}Which Version PostgreSQL are you want to install:${CEND} " num3

    case $num3 in
    1)
        postgresql_install_version=${PostgreSQL_13_version:?}
        SOURCE_SCRIPT "${FunctionPath:?}"/install/PostgreSQL-13.sh
        PostgreSQL_13_Install_Main 2>&1 | tee "$script_dir"/logs/Install_PostgreSQL13.log
        select_postgresql_install
        ;;
    2)
        postgresql_install_version=${PostgreSQL_12_version:?}
        SOURCE_SCRIPT "${FunctionPath:?}"/install/PostgreSQL-12.sh
        PostgreSQL_12_Install_Main 2>&1 | tee "$script_dir"/logs/Install_PostgreSQL12.log
        select_postgresql_install
        ;;
    3)
        select_database_install
        ;;
    4)
        clear
        exit 0
        ;;
    *)
        select_postgresql_install
        ;;
    esac
}
