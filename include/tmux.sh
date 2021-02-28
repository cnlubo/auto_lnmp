#!/bin/bash
# @Author: cnak47
# @Date: 2020-01-03 11:20:00
# @LastEditors: cnak47
# @LastEditTime: 2021-02-28 10:22:34
# @Description:
# #

install_tmux() {

    INFO_MSG " tmux install begin ..... "
    yum -y install ncurses-devel automake
    # Install libevent first
    cd "${script_dir:?}"/src || exit
    # shellcheck disable=SC2034
    src_url=https://github.com/libevent/libevent/releases/download/release-${libevent_version:?}/libevent-${libevent_version:?}.tar.gz
    [ ! -f libevent-"$libevent_version".tar.gz ] && Download_src
    [ -d libevent-"${libevent_version}" ] && rm -rf libevent-"${libevent_version}"
    tar xzf libevent-"${libevent_version}".tar.gz
    cd libevent-"${libevent_version}" || exit
    ./configure && make -j"${CpuProNum:?}" && make install
    # shellcheck disable=SC2181
    if [ $? -eq 0 ]; then
        SUCCESS_MSG "libevent-${libevent_version} install success !!!"
    else
        FAILURE_MSG "libevent-${libevent_version} install failure !!!"
        exit 1
    fi
    cd .. && rm -rf libevent-"${libevent_version}"
    # tmux install
    [ ! -d tmux ] && git clone https://github.com/tmux/tmux.git
    cd tmux && git pull && sh autogen.sh
    CFLAGS="-I/usr/local/include" LDFLAGS="-L/usr/local/lib" ./configure
    make -j"${CpuProNum:?}" && make install
    # shellcheck disable=SC2181
    if [ $? -eq 0 ]; then
        SUCCESS_MSG "tmux install success !!!"
    else
        FAILURE_MSG "tmux install failure !!! "
    fi
    unset LDFLAGS
    if [ "${OS_BIT}" == "64" ]; then
        [ -h /usr/lib64/libevent-2.1.so.7 ] && rm -rf /usr/lib64/libevent-2.1.so.7
        ln -s /usr/local/lib/libevent-2.1.so.7 /usr/lib64/libevent-2.1.so.7
        ln -s /usr/local/lib/libevent_core-2.1.so.7 /usr/lib64/libevent_core-2.1.so.7
    else
        [ -h /usr/lib64/libevent-2.1.so.7 ] && rm -rf /usr/lib64/libevent-2.1.so.7
        ln -s /usr/local/lib/libevent-2.1.so.7 /usr/lib/libevent-2.1.so.7
        ln -s /usr/local/lib/libevent_core-2.1.so.7 /usr/lib/libevent_core-2.1.so.7
    fi

}
