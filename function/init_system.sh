#!/bin/bash
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              init_system.sh
# @Desc
#----------------------------------------------------------------------------
SOURCE_SCRIPT ${script_dir:?}/include/check_deps.sh
SOURCE_SCRIPT ${script_dir:?}/include/configure_os.sh

select_system_setup_function(){

    echo -e "${CMSG}[Initialization $OS] **************************************************>>${CEND}\n";
    # modify ssh port
    if [ -e "/etc/ssh/sshd_config" ]; then
        [ -z "`grep ^Port /etc/ssh/sshd_config`" ] && ssh_port=22 || ssh_port=`grep ^Port /etc/ssh/sshd_config | awk '{print $2}'`
        while :; do
            echo
            read -p "Please input SSH port(Default: $ssh_port): " SSH_PORT
            [ -z "$SSH_PORT" ] && SSH_PORT=$ssh_port
            # shellcheck disable=SC1073
            if [ $SSH_PORT -eq 22 ] || [ $SSH_PORT -gt 1024 ] && [ $SSH_PORT -lt 65535 ]; then
                break
            else
                echo -e "${CWARNING}input error! Input range: 22,1025~65534${CEND}\n"
            fi
        done

        if [ -z "`grep ^Port /etc/ssh/sshd_config`" ] && [ "$SSH_PORT" != '22' ]; then
            sed -i "s@^#Port.*@&\nPort $SSH_PORT@" /etc/ssh/sshd_config
        elif [ -n "`grep ^Port /etc/ssh/sshd_config`" ]; then
            sed -i "s@^Port.*@Port $SSH_PORT@" /etc/ssh/sshd_config
        fi
        # 禁止root 用户登陆
        # PermitRootLogin no
    fi

    # 创建默认普通用户
    echo
    read -p "Please input a typical user(default:${default_user:?})" Typical_User
    Typical_User="${Typical_User:=$default_user}"
    id $Typical_User >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CWARNING}[ Input user($Typical_User) exist !!!] *******************************>>${CEND}\n"
    else
        system_user_setup $Typical_User
    fi

    # 安装必要的依赖和初始化系统
    case "${OS}" in
        "CentOS")
            installDepsCentOS 2>&1 | tee $script_dir/logs/deps_install.log
            common_setup 2>&1 | tee $script_dir/logs/init_centos.log
            centos_setup 2>&1 | tee -a $script_dir/logs/init_centos.log
            ;;
        "Debian")
            installDepsDebian 2>&1 | tee $script_dir/logs/deps_install.log
            $script_dir/include/init_Debian.sh 2>&1 | tee -a $script_dir/logs/init_debian.log
            ;;
        "Ubuntu")
            installDepsUbuntu 2>&1 | tee $script_dir//logs/deps_install.log
            ${script_dir:?}/include/init_Ubuntu.sh 2>&1 | tee -a ${script_dir:?}/logs/init_ubuntu.log
            ;;
    esac

    # 源代码安装软件
    installDepsBySrc 2>&1 | tee $script_dir/logs/soft_install.log
    echo -e "${CMSG} [ Initialization $OS OK please reboot] ***********************>>${CEND}\n";
    select_main_menu
}
