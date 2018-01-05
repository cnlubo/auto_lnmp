#!/bin/bash
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              init_system.sh
# @Desc
#----------------------------------------------------------------------------
SOURCE_SCRIPT ${script_dir:?}/include/check_deps.sh
select_system_setup_function(){

    echo "${CMSG}[Initialization $OS] **************************************************>>${CEND}";
    # modify ssh port
    if [ -e "/etc/ssh/sshd_config" ]; then
        [ -z "`grep ^Port /etc/ssh/sshd_config`" ] && ssh_port=22 || ssh_port=`grep ^Port /etc/ssh/sshd_config | awk '{print $2}'`
        while :; do
            echo
            read -p "Please input SSH port(Default: $ssh_port): " SSH_PORT
            [ -z "$SSH_PORT" ] && SSH_PORT=$ssh_port
            # shellcheck disable=SC1073
            #if [ $SSH_PORT -eq 22 >/dev/null 2>&1 -o $SSH_PORT -gt 1024 >/dev/null 2>&1 -a $SSH_PORT -lt 65535 >/dev/null 2>&1 ]; then
            if [ $SSH_PORT -eq 22 ] || [ $SSH_PORT -gt 1024 ] && [ $SSH_PORT -lt 65535 ]; then
                break
            else
                echo "${CWARNING}input error! Input range: 22,1025~65534${CEND}"
            fi
        done

        #if [ -z "`grep ^Port /etc/ssh/sshd_config`" -a "$SSH_PORT" != '22' ]; then
        if [ -z "`grep ^Port /etc/ssh/sshd_config`" ] && [ "$SSH_PORT" != '22' ]; then
            sed -i "s@^#Port.*@&\nPort $SSH_PORT@" /etc/ssh/sshd_config
        elif [ -n "`grep ^Port /etc/ssh/sshd_config`" ]; then
            sed -i "s@^Port.*@Port $SSH_PORT@" /etc/ssh/sshd_config
        fi
    fi
    # 创建默认普通用户
    echo
    read -p "Please input a typical user(default:${default_user:?})" Typical_User
    Typical_User="${Typical_User:=$default_user}"
    id $Typical_User >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "${CWARNING}Input user($Typical_User)exist${CEND}"
    else
        # 创建用户设置密码
        useradd $Typical_User
        echo ${default_pass:?} | passwd $Typical_User --stdin  &>/dev/null
        #sed -i "s@^default_user.*@default_user=$Typical_User@" ./options.conf
        #SOURCE_SCRIPT $ScriptPath/options.conf
        # echo $default_user
    fi
    sed -i "s@^default_user.*@default_user=$Typical_User@" ./options.conf
    SOURCE_SCRIPT ${ScriptPath:?}/options.conf
    # # 安装必要的依赖和初始化系统
    case "${OS}" in
        "CentOS")
            installDepsCentOS 2>&1 | tee $script_dir/logs/deps_install.log
            $script_dir/include/init_CentOS.sh 2>&1 | tee $script_dir/logs/init_centos.log
        ;;
        "Debian")
            installDepsDebian 2>&1 | tee $script_dir/logs/install.log
            $script_dir/include/init_Debian.sh 2>&1 | tee -a $script_dir/logs/install.log
        ;;
        "Ubuntu")
            installDepsUbuntu 2>&1 | tee $script_dir//logs/install.log
            ${script_dir:?}/include/init_Ubuntu.sh 2>&1 | tee -a ${script_dir:?}/logs/install.log
        ;;
    esac

    # 源代码安装软件
    installDepsBySrc 2>&1 | tee $script_dir/logs/soft_install.log
    echo "${CMSG}******************    [Initialization $OS OK please reboot] ***********************************************>>${CEND}";
    select_main_menu;
}
