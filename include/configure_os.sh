#!/bin/bash
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

if [ "${CentOS_RHEL_version:?}" == '5' ]; then
        sed -i 's@^[3-6]:2345:respawn@#&@g' /etc/inittab
        sed -i 's@^ca::ctrlaltdel@#&@' /etc/inittab
        sed -i 's@LANG=.*$@LANG="en_US.UTF-8"@g' /etc/sysconfig/i18n
    elif [ "${CentOS_RHEL_version}" == '6' ]; then
        sed -i 's@^ACTIVE_CONSOLES.*@ACTIVE_CONSOLES=/dev/tty[1-2]@' /etc/sysconfig/init
        sed -i 's@^start@#start@' /etc/init/control-alt-delete.conf
        sed -i 's@LANG=.*$@LANG="en_US.UTF-8"@g' /etc/sysconfig/i18n
    elif [ "${CentOS_RHEL_version}" == '7' ]; then
        sed -i 's@LANG=.*$@LANG="en_US.UTF-8"@g' /etc/locale.conf
    fi

    # service rsyslog restart
    service sshd restart

}
