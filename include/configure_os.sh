#!/bin/bash
# @Author: cnak47
# @Date: 2018-04-30 23:59:11
# @LastEditors: cnak47
# @LastEditTime: 2020-10-24 12:28:12
# @Description:
# #

common_setup() {

    INFO_MSG "modify limits.conf ..... "
    # /etc/security/limits.conf
    for file in /etc/security/limits.d/*nproc.conf; do
        if [ -e "$file" ]; then
            mv "$file" "${file:?}"_bk
        fi
    done
    sed -i '/^# End of file/,$d' /etc/security/limits.conf
    cat >>/etc/security/limits.conf <<EOF
# End of file
* soft nproc   524288
* hard nproc   524288
* soft nofile  524288
* hard nofile  524288
* hard memlock unlimited
* soft memlock unlimited
EOF
    INFO_MSG "Setting timezone ....."
    rm -rf /etc/localtime
    ln -s /usr/share/zoneinfo/"$TZ" /etc/localtime
}

centos_setup() {

    INFO_MSG "syncing system time ..... "
    systemctl stop ntpd && systemctl disable ntpd && systemctl enable chronyd
    # systemctl stop ntpd && systemctl disable ntpd && ntpdate pool.ntp.org
    # # every 20 minute run ntpdate
    # # [ ! -e "/var/spool/cron/root" -o -z "$(grep 'ntpdate' /var/spool/cron/root)" ] && { echo "*/20 * * * * $(which ntpdate) pool.ntp.org > /dev/null 2>&1" >> /var/spool/cron/root;chmod 600 /var/spool/cron/root; }
    # # shellcheck disable=SC2143
    # # shellcheck disable=SC2230
    # [ ! -e "/var/spool/cron/root" ] || [ -z "$(grep 'ntpdate' /var/spool/cron/root)" ] && {
    #     echo "*/20 * * * * $(which ntpdate) pool.ntp.org > /dev/null 2>&1" >>/var/spool/cron/root
    #     chmod 600 /var/spool/cron/root
    # }
}
system_user_setup() {
    system_user="$1"
    id "$system_user" >/dev/null 2>&1
    # if [ $? -eq 0 ]; then
    if id "$system_user" >/dev/null 2>&1; then
        # echo -e "${CWARNING}[ system user($system_user) already exists !!!] ****>>${CEND}\n"
        WARNING_MSG "system user($system_user) already exists !!!"
    else
        # 创建用户设置密码
        useradd "$system_user"
        yum -y install expect
        default_pass=$(mkpasswd -l 8)
        echo "${default_pass:?}" | passwd "$system_user" --stdin &>/dev/null
        echo
        echo "${CRED}[system user $system_user passwd:${default_pass:?} !!!!! ] ****>>${CEND}" | tee ${script_dir:?}/logs/pp.log
        #| tee ${script_dir:?}/logs/pp.log
        echo
        # sudo 权限
        [ -f /etc/sudoers.d/"$system_user" ] && rm -rf /etc/sudoers.d/"$system_user"
        cat >/etc/sudoers.d/"$system_user" <<EOF
Defaults    secure_path = /usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
$system_user   ALL=(ALL)  NOPASSWD: ALL
EOF
        chmod 400 /etc/sudoers.d/"$system_user"
    fi
    sed -i "s@^default_user.*@default_user=$system_user@" "${ScriptPath:?}"/config/common.conf
    SOURCE_SCRIPT "${ScriptPath:?}"/config/common.conf
}

app_user_setup() {
    app_user="$1"
    if id "$app_user" >/dev/null 2>&1; then
        WARNING_MSG "[ Application user($app_user) already exists !!!]"
    else
        # grep "${app_user:?}" /etc/group >/dev/null 2>&1
        # # shellcheck disable=SC2181
        # if [ ! $? -eq 0 ]; then
        #     groupadd "$app_user"
        # fi
        # id $app_user >/dev/null 2>&1
        # if [ ! $? -eq 0 ]; then
        #     useradd -g $app_user -M -s /sbin/nologin $app_user
        # fi
        if ! grep "${app_user:?}" /etc/group >/dev/null 2>&1; then
            groupadd "$app_user"
        fi
        if ! id "$app_user" >/dev/null 2>&1; then
            useradd -g "$app_user" -M -s /sbin/nologin "$app_user"
        fi
    fi
}

share_software_install() {

    zlib_install
}

zlib_install() {

    if [ ! -e "${zlib_install_dir:?}"/lib/libz.a ]; then

        INFO_MSG " zlib-${zlib_version:?} install ..... "
        cd "${script_dir:?}"/src || exit
        # shellcheck disable=SC2034
        src_url=http://zlib.net/zlib-${zlib_version:?}.tar.gz
        [ ! -f zlib-"${zlib_version:?}".tar.gz ] && Download_src
        [ -d zlib-"${zlib_version:?}" ] && rm -rf zlib-"${zlib_version:?}"
        tar xf zlib-"${zlib_version:?}".tar.gz
        cd zlib-"${zlib_version:?}" || exit
        ./configure --prefix="${zlib_install_dir:?}" && make && make install
        if [ -f "${zlib_install_dir:?}"/lib/libz.a ]; then
            SUCCESS_MSG " zlib-${zlib_version:?} installed successful ..... "
            [ -f etc/ld.so.conf.d/sharelib.conf ] && rm -rf etc/ld.so.conf.d/sharelib.conf
            echo "${zlib_install_dir:?}/lib" >/etc/ld.so.conf.d/sharelib.conf
            ldconfig
        else
            FAILURE_MSG " install zlib-${zlib_version:?} failed,Please contact the author ..... "
            # kill -9 $$
        fi
    else
        INFO_MSG " zlib-${zlib_version:?} have installed ..... "
    fi
}
pcre_install() {

    if [ ! -e "${pcre_install_dir:?}"/lib/libpcre.a ]; then
        cd "${script_dir:?}"/src || exit
        # shellcheck disable=SC2034
        src_url=https://sourceforge.net/projects/pcre/files/pcre/${pcre_version:?}/pcre-$pcre_version.tar.gz/download
        [ ! -f pcre-"$pcre_version".tar.gz ] && Download_src && mv download pcre-"$pcre_version".tar.gz
        [ -d pcre-"$pcre_version" ] && rm -rf pcre-"$pcre_version"
        tar xf pcre-"$pcre_version".tar.gz
        cd pcre-"$pcre_version" || exit
        ./configure --prefix="${pcre_install_dir:?}" --enable-utf8 --enable-unicode-properties
        make && make install
        if [ -f "${pcre_install_dir:?}"/lib/libpcre.a ]; then
            SUCCESS_MSG " pcre-${pcre_version:?} installed successful ..... "
            [ -f etc/ld.so.conf.d/pcre.conf ] && rm -rf etc/ld.so.conf.d/pcre.conf
            echo "${pcre_install_dir:?}/lib" >/etc/ld.so.conf.d/pcre.conf
            ldconfig
        else
            FAILURE_MSG " install pcre-${pcre_install_dir:?} failed,Please contact the author !!!"
            kill -9 $$
        fi
    else
        INFO_MSG " pcre-${pcre_install_dir:?} have installed "
    fi

}

libxml2_install() {

    if [ ! -e "${libxml2_install_dir:?}"/lib/libxml2.a ]; then
        cd "${script_dir:?}"/src || exit
        # shellcheck disable=SC2034
        src_url=https://git.gnome.org/browse/libxml2/snapshot/libxml2-${libxml2_version:?}.tar.xz
        [ ! -f libxml2-"${libxml2_version:?}".tar.xz ] && Download_src
        [ -d libxml2-"${libxml2_version:?}" ] && rm -rf libxml2-"${libxml2_version:?}"
        tar xf libxml2-"${libxml2_version:?}".tar.xz
        cd libxml2-"${libxml2_version:?}" || exit
        yum install -y libtool
        ./configure --prefix="${libxml2_install_dir:?}" && make && make install
        if [ -f "${libxml2_install_dir:?}"/lib/libxml2.a ]; then

            SUCCESS_MSG " libxml2-${libxml2_version:?} installed successful ..... "

            [ -f etc/ld.so.conf.d/sharelib.conf ] && rm -rf etc/ld.so.conf.d/sharelib.conf
            echo "${libxml2_install_dir:?}/lib" >/etc/ld.so.conf.d/sharelib.conf
            ldconfig
        else
            FAILURE_MSG " install libxml2-${libxml2_version:?} failed,Please contact the author ..... "
            kill -9 $$
        fi
    else
        INFO_MSG " libxml2-${libxml2_version:?} have installed ..... "
    fi

}
