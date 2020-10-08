#!/bin/bash
# @Author: cnak47
# @Date: 2019-12-31 17:43:14
# @LastEditors: cnak47
# @LastEditTime: 2020-01-02 11:31:11
# @Description:
# #

install_devtoolset() {

    if [[ "$(
        rpm -ql centos-release-scl >/dev/null 2>&1
        echo $?
    )" -ne '0' ]]; then
        INFO_MSG "install centos-release-scl for newer gcc and g++ versions"
        # shellcheck disable=SC2143
        if [[ -z "$(rpm -qa | grep rpmforge)" ]]; then
            yum -y install centos-release-scl
        else
            yum -y install centos-release-scl --disablerepo=rpmforge
        fi
    fi

    if [ ! -f /opt/rh/devtoolset-6/root/usr/bin/gcc ] || [ ! -f /opt/rh/devtoolset-6/root/usr/bin/g++ ]; then
        INFO_MSG "install devtoolset-6 gcc g++ binutils..... "
        yum -y install devtoolset-6-gcc devtoolset-6-gcc-c++ devtoolset-6-binutils
    fi
    echo
    /opt/rh/devtoolset-6/root/usr/bin/gcc --version
    /opt/rh/devtoolset-6/root/usr/bin/g++ --version

    if [ ! -f /opt/rh/devtoolset-7/root/usr/bin/gcc ] || [ ! -f /opt/rh/devtoolset-7/root/usr/bin/g++ ]; then
        INFO_MSG "install devtoolset-7 gcc g++ binutils..... "
        yum -y install devtoolset-7-gcc devtoolset-7-gcc-c++ devtoolset-7-binutils
    fi
    echo
    /opt/rh/devtoolset-7/root/usr/bin/gcc --version
    /opt/rh/devtoolset-7/root/usr/bin/g++ --version

    if [ ! -f /opt/rh/devtoolset-8/root/usr/bin/gcc ] || [ ! -f /opt/rh/devtoolset-8/root/usr/bin/g++ ]; then
        INFO_MSG "install devtoolset-8 gcc g++ binutils..... "
        yum -y install devtoolset-8-gcc devtoolset-8-gcc-c++ devtoolset-8-binutils
    fi
    echo
    /opt/rh/devtoolset-8/root/usr/bin/gcc --version
    /opt/rh/devtoolset-8/root/usr/bin/g++ --version

}
