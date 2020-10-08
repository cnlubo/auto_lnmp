#!/bin/bash
# @Author: cnak47
# @Date: 2018-04-30 23:59:11
# @LastEditors: cnak47
# @LastEditTime: 2020-05-14 18:51:18
# @Description:
# #

SOURCE_SCRIPT "${script_dir:?}"/include/check_deps.sh
SOURCE_SCRIPT "${script_dir:?}"/include/configure_os.sh

select_system_setup_function() {

    INFO_MSG "Initialization $OS ..... "
    # modify ssh port
    if [ -e "/etc/ssh/sshd_config" ]; then
        # shellcheck disable=SC2006
        # shellcheck disable=SC2143
        [ -z "$(grep ^Port /etc/ssh/sshd_config)" ] && ssh_port=22 || ssh_port=$(grep ^Port /etc/ssh/sshd_config | awk '{print $2}')
        while :; do
            echo
            # shellcheck disable=SC2162
            read -p "Please input SSH port(Default: $ssh_port): " SSH_PORT
            [ -z "$SSH_PORT" ] && SSH_PORT=$ssh_port
            # shellcheck disable=SC1073
            if [ "$SSH_PORT" -eq 22 ] || [ "$SSH_PORT" -gt 1024 ] && [ "$SSH_PORT" -lt 65535 ]; then
                break
            else
                WARNING_MSG "input error! Input range: 22,1025~65534"
            fi
        done
        # shellcheck disable=SC2143
        if [ -z "$(grep ^Port /etc/ssh/sshd_config)" ] && [ "$SSH_PORT" != '22' ]; then
            sed -i "s@^#Port.*@&\nPort $SSH_PORT@" /etc/ssh/sshd_config
        elif [ -n "$(grep ^Port /etc/ssh/sshd_config)" ]; then
            sed -i "s@^Port.*@Port $SSH_PORT@" /etc/ssh/sshd_config
        fi
        # 禁止root 用户登陆
        # PermitRootLogin no
    fi

    # 创建默认普通用户
    echo
    # shellcheck disable=SC2162
    read -p "Please input a typical user(default:${default_user:?})" Typical_User
    Typical_User="${Typical_User:=$default_user}"
    # id "$Typical_User" >/dev/null 2>&1
    # if [ $? -eq 0 ]; then
    if id "$Typical_User" >/dev/null 2>&1; then
        WARNING_MSG "Input user($Typical_User) exist !!!"
    else
        system_user_setup "$Typical_User"
    fi

    # 安装必要的依赖和初始化系统
    case "${OS}" in
    "CentOS")
         2>&1 | tee "$script_dir"/logs/deps_install.log
        common_setup 2>&1 | tee "$script_dir"/logs/init_centos.log
        centos_setup 2>&1 | tee -a "$script_dir"/logs/init_centos.log
        ;;
    "Debian")
        installDepsDebian 2>&1 | tee "$script_dir"/logs/deps_install.log
        "$script_dir"/include/init_Debian.sh 2>&1 | tee -a "$script_dir"/logs/init_debian.log
        ;;
    "Ubuntu")
        installDepsUbuntu 2>&1 | tee "$script_dir"/logs/deps_install.log
        "${script_dir:?}"/include/init_Ubuntu.sh 2>&1 | tee -a "${script_dir:?}"/logs/init_ubuntu.log
        ;;
    esac

    # 源代码安装软件
    installDepsBySrc 2>&1 | tee "$script_dir"/logs/soft_install.log
    INFO_MSG "Initialization $OS OK please reboot ....."
    select_main_menu
}
