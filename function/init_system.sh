#!/bin/bash
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              init_system.sh
# @Desc
#----------------------------------------------------------------------------
SOURCE_SCRIPT ${script_dir:?}/include/check_deps.sh
SOURCE_SCRIPT ${script_dir:?}/include/configure_os.sh

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
        yum install expect
        default_pass=`mkpasswd -l 8`
        echo ${default_pass:?} | passwd $Typical_User --stdin  &>/dev/null
        echo
        echo "${CRED}[system user $Typical_User passwd:${default_pass:?} !!!!! ] *******************************>>${CEND}" | tee $script_dir/logs/pp.log
        echo
        # sudo 权限
        [ -f /etc/sudoers.d/ak47 ] && rm -rf /etc/sudoers.d/ak47
        echo " $Typical_User   ALL=(ALL)  NOPASSWD: ALL " >> /etc/sudoers.d/ak47 && chmod 400 /etc/sudoers.d/ak47
    fi
    sed -i "s@^default_user.*@default_user=$Typical_User@" ./options.conf
    SOURCE_SCRIPT ${ScriptPath:?}/options.conf
    # 安装必要的依赖和初始化系统
    case "${OS}" in
        "CentOS")
            installDepsCentOS 2>&1 | tee $script_dir/logs/deps_install.log
            common_setup 2>&1 | tee $script_dir/logs/init_centos.log
            centos_setup 2>&1 | tee -a $script_dir/logs/init_centos.log
            # $script_dir/include/init_CentOS.sh 2>&1 | tee $script_dir/logs/init_centos.log
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
    echo "${CMSG}******************    [Initialization $OS OK please reboot] ***********************************************>>${CEND}";
    select_main_menu;
}
