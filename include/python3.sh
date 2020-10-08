#!/bin/bash
# @Author: cnak47
# @Date: 2020-01-03 10:27:16
# @LastEditors: cnak47
# @LastEditTime: 2020-02-05 11:57:51
# @Description:
# #

install_pyenv() {

    if id "${default_user:?}" >/dev/null 2>&1; then
        WARNING_MSG "${default_user:?} not exists please create it !!!!!"
        exit 1
    else
        echo ""
    fi
}

install_python36() {

    if [[ "$(
        rpm -ql centos-release-scl >/dev/null 2>&1
        echo $?
    )" -ne '0' ]]; then
        INFO_MSG "install centos-release-scl for python36"
        # shellcheck disable=SC2143
        if [[ -z "$(rpm -qa | grep rpmforge)" ]]; then
            yum -y install centos-release-scl
        else
            yum -y install centos-release-scl --disablerepo=rpmforge
        fi
    fi
    
    if [ ! -f /opt/rh/rh-python36/root/bin/python3.6 ]; then
        INFO_MSG "install python3.6..... "
        yum install -y rh-python36
    fi
    # enable python3.6
    if [ -f /root/.zshrc ] || [ -h /root/.zshrc ]; then
        if ! grep "source /opt/rh/rh-python36/enable" /root/.zshrc >/dev/null 2>&1; then
            echo "source /opt/rh/rh-python36/enable" >>/root/.zshrc
        fi
    fi
    # shellcheck disable=SC1091
    source /opt/rh/rh-python36/enable
    python --version

    if id "${default_user:?}" >/dev/null 2>&1; then
        INFO_MSG " user [${default_user:?}] enable python3.6  ....."
        if [ -f /home/"${default_user:?}"/.zshrc ] || [ -h /home/"${default_user:?}"/.zshrc ]; then
            if ! grep "source /opt/rh/rh-python36/enable" /home/"${default_user:?}"/.zshrc >/dev/null 2>&1; then
                echo "source /opt/rh/rh-python36/enable" >>/home/"${default_user:?}"/.zshrc
            fi
        fi
    fi
    # pip.conf
    [ -f /etc/pip.conf ] && rm -rf /etc/pip.conf
    cp "${script_dir:?}"/config/pip.conf /etc/pip.conf
}
