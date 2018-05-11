#!/bin/bash
# shellcheck disable=SC2164
# -------------------------------------------
# @Author  : cnlubo (454331202@qq.com)
# @Link    :
# @desc    : 配置优化系统
# @filename : configure_os.sh
#--------------------------------------------

common_setup () {

    echo -e "${CMSG}[ modify limits.conf ] **********************************>>${CEND}\n"
    # /etc/security/limits.conf
    #[ -e /etc/security/limits.d/*nproc.conf ] && rename nproc.conf nproc.conf_bk /etc/security/limits.d/*nproc.conf
    for file in /etc/security/limits.d/*nproc.conf
    do
        if [ -e "$file" ]
        then
            mv $file ${file:?}_bk
        fi
    done
    sed -i '/^# End of file/,$d' /etc/security/limits.conf
    cat >> /etc/security/limits.conf <<EOF
    # End of file
    * soft nproc 65535
    * hard nproc 65535
    * soft nofile 65535
    * hard nofile 65535
EOF
    echo -e "${CMSG}[ Setting timezone ] **********************************>>${CEND}\n"
    rm -rf /etc/localtime
    ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

    # echo "${CMSG}[ Setting timezone ] **********************************>>${CEND}"
    # systemctl stop ntpd
    # systemctl disable ntpd
    # ntpdate pool.ntp.org
    # # every 20 minute run ntpdate
    # # [ ! -e "/var/spool/cron/root" -o -z "$(grep 'ntpdate' /var/spool/cron/root)" ] && { echo "*/20 * * * * $(which ntpdate) pool.ntp.org > /dev/null 2>&1" >> /var/spool/cron/root;chmod 600 /var/spool/cron/root; }
    # [ ! -e "/var/spool/cron/root" ] || [ -z "$(grep 'ntpdate' /var/spool/cron/root)" ] && { echo "*/20 * * * * $(which ntpdate) pool.ntp.org > /dev/null 2>&1" >> /var/spool/cron/root;chmod 600 /var/spool/cron/root; }

}

centos_setup() {

    echo -e "${CMSG}[ update time ] **********************************>>${CEND}\n"
    systemctl stop ntpd && systemctl disable ntpd && ntpdate pool.ntp.org
    # every 20 minute run ntpdate
    # [ ! -e "/var/spool/cron/root" -o -z "$(grep 'ntpdate' /var/spool/cron/root)" ] && { echo "*/20 * * * * $(which ntpdate) pool.ntp.org > /dev/null 2>&1" >> /var/spool/cron/root;chmod 600 /var/spool/cron/root; }
    [ ! -e "/var/spool/cron/root" ] || [ -z "$(grep 'ntpdate' /var/spool/cron/root)" ] && { echo "*/20 * * * * $(which ntpdate) pool.ntp.org > /dev/null 2>&1" >> /var/spool/cron/root;chmod 600 /var/spool/cron/root; }

    # if [ "${CentOS_RHEL_version:?}" == '5' ]; then
    #         sed -i 's@^[3-6]:2345:respawn@#&@g' /etc/inittab
    #         sed -i 's@^ca::ctrlaltdel@#&@' /etc/inittab
    #         sed -i 's@LANG=.*$@LANG="en_US.UTF-8"@g' /etc/sysconfig/i18n
    #     elif [ "${CentOS_RHEL_version}" == '6' ]; then
    #         sed -i 's@^ACTIVE_CONSOLES.*@ACTIVE_CONSOLES=/dev/tty[1-2]@' /etc/sysconfig/init
    #         sed -i 's@^start@#start@' /etc/init/control-alt-delete.conf
    #         sed -i 's@LANG=.*$@LANG="en_US.UTF-8"@g' /etc/sysconfig/i18n
    #     elif [ "${CentOS_RHEL_version}" == '7' ]; then
    #         sed -i 's@LANG=.*$@LANG="en_US.UTF-8"@g' /etc/locale.conf
    #     fi
    #
    #     # service rsyslog restart
    #     service sshd restart

}
system_user_setup()
{
    system_user="$1"
    id $system_user >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CWARNING}[ system user($system_user) already exists !!!] ****>>${CEND}\n"
    else
        # 创建用户设置密码
        useradd $system_user
        yum -y install expect
        default_pass=`mkpasswd -l 8`
        echo ${default_pass:?} | passwd $system_user --stdin  &>/dev/null
        echo
        echo "${CRED}[system user $system_user passwd:${default_pass:?} !!!!! ] ****>>${CEND}" | tee ${script_dir:?}/logs/pp.log
        echo
        # sudo 权限
        [ -f /etc/sudoers.d/$system_user ] && rm -rf /etc/sudoers.d/$system_user
        cat > /etc/sudoers.d/$system_user << EOF
Defaults    secure_path = /usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
$system_user   ALL=(ALL)  NOPASSWD: ALL
EOF
        chmod 400 /etc/sudoers.d/$system_user
    fi
    sed -i "s@^default_user.*@default_user=$system_user@" ${ScriptPath:?}/config/common.conf
    SOURCE_SCRIPT ${ScriptPath:?}/config/common.conf
}

 app_user_setup()
{
    app_user="$1"
    id $app_user >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        WARNING_MSG "[ Application user($app_user) already exists !!!]"
    else
        grep ${app_user:?} /etc/group >/dev/null 2>&1
        if [ ! $? -eq 0 ]; then
            groupadd $app_user;
        fi
        id $app_user >/dev/null 2>&1
        if [ ! $? -eq 0 ]; then
            useradd -g $app_user  -M -s /sbin/nologin $app_user
        fi
    fi
}


share_software_install(){

    zlib_install
}

zlib_install() {

    if [ ! -e ${zlib_install_dir:?}/lib/libz.a ]; then

        INFO_MSG "[zlib-${zlib_version:?} begin install !!!]"
        cd ${script_dir:?}/src
        # shellcheck disable=SC2034
        src_url=http://zlib.net/zlib-${zlib_version:?}.tar.gz
        [ ! -f zlib-${zlib_version:?}.tar.gz ] && Download_src
        [ -d zlib-${zlib_version:?} ] && rm -rf zlib-${zlib_version:?}
        tar xf zlib-${zlib_version:?}.tar.gz && cd zlib-${zlib_version:?}
        ./configure --prefix=${zlib_install_dir:?} && make && make install
        if [ -f ${zlib_install_dir:?}/lib/libz.a ]; then
            SUCCESS_MSG "[zlib-${zlib_version:?} installed successful !!!]"
            [ -f etc/ld.so.conf.d/sharelib.conf ] && rm -rf etc/ld.so.conf.d/sharelib.conf
            echo "${zlib_install_dir:?}/lib" > /etc/ld.so.conf.d/sharelib.conf
            ldconfig
        else
            FAILURE_MSG "[install zlib-${zlib_version:?} failed,Please contact the author !!!]"
            # kill -9 $$
        fi
    else
        INFO_MSG "[zlib-${zlib_version:?} have installed !!!]"
    fi
}
pcre_install() {

    if [ ! -e ${pcre_install_dir:?}/lib/libpcre.a ]; then
        cd ${script_dir:?}/src
        # shellcheck disable=SC2034
        src_url=https://sourceforge.net/projects/pcre/files/pcre/${pcre_version:?}/pcre-$pcre_version.tar.gz/download
        [ ! -f pcre-$pcre_version.tar.gz ] && Download_src && mv download pcre-$pcre_version.tar.gz
        [ -d pcre-$pcre_version ] && rm -rf pcre-$pcre_version
        tar xf pcre-$pcre_version.tar.gz && cd pcre-$pcre_version
        ./configure --prefix=${pcre_install_dir:?} --enable-utf8 --enable-unicode-properties
        make && make install
        if [ -f ${pcre_install_dir:?}/lib/libpcre.a ]; then
            SUCCESS_MSG "[pcre-${pcre_version:?} installed successful !!!]"
            [ -f etc/ld.so.conf.d/pcre.conf ] && rm -rf etc/ld.so.conf.d/pcre.conf
            echo "${pcre_install_dir:?}/lib" > /etc/ld.so.conf.d/pcre.conf
            ldconfig
        else
            FAILURE_MSG "[install pcre-${pcre_install_dir:?} failed,Please contact the author !!!]"
            kill -9 $$
        fi
    else
        INFO_MSG "[pcre-${pcre_install_dir:?} have installed !!!]"
    fi

}

libxml2_install() {

    if [ ! -e ${libxml2_install_dir:?}/lib/libxml2.a ]; then
        cd ${script_dir:?}/src
        # shellcheck disable=SC2034
        src_url=https://git.gnome.org/browse/libxml2/snapshot/libxml2-${libxml2_version:?}.tar.xz
        [ ! -f libxml2-${libxml2_version:?}.tar.xz ] && Download_src
        [ -d libxml2-${libxml2_version:?} ] && rm -rf libxml2-${libxml2_version:?}
        tar xf libxml2-${libxml2_version:?}.tar.xz && cd libxml2-${libxml2_version:?}
        yum install -y libtool
        ./configure --prefix=${libxml2_install_dir:?} && make && make install
        if [ -f ${libxml2_install_dir:?}/lib/libxml2.a ]; then
            SUCCESS_MSG "[libxml2-${libxml2_version:?} installed successful !!!]"
            [ -f etc/ld.so.conf.d/sharelib.conf ] && rm -rf etc/ld.so.conf.d/sharelib.conf
            echo "${libxml2_install_dir:?}/lib" > /etc/ld.so.conf.d/sharelib.conf
            ldconfig
        else
            FAILURE_MSG "[install libxml2-${libxml2_version:?} failed,Please contact the author !!!]"
            kill -9 $$
        fi
    else
        INFO_MSG "[ libxml2-${libxml2_version:?} have installed !!!]"
    fi

}

libxslt_install()
{
    echo
    # ./configure --prefix=/usr/local/software/sharelib \
        #   --with-python=/usr/local/python2.7.14/bin/python \
        #   --with-libxml-src=/usr/local/auto_lnmp/src/libxml2-2.9.8
    #   --with-libxml-prefix=usr/local/software/sharelib \
        #   --with-libxml-include-prefix=/usr/local/software/sharelib/include  \
        #   --with-libxml-libs-prefix=/usr/local/software/sharelib/lib
}
