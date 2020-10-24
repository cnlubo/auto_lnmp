#!/bin/bash
# @Author: cnak47
# @Date: 2018-04-30 23:59:11
# @LastEditors: cnak47
# @LastEditTime: 2020-10-08 19:51:01
# @Description:
# #

installDepsCentOS() {

    [ -e '/etc/yum.conf' ] && sed -i 's@^exclude@#exclude@' /etc/yum.conf
    # shellcheck disable=SC2143
    if [ -z "$(grep -w epel /etc/yum.repos.d/*.repo)" ]; then
        INFO_MSG " Install yum-fastestmirror epel-release ..... "
        yum -y install yum-fastestmirror epel-release && yum clean all
    fi
    INFO_MSG " Disable selinux ..... "
    setenforce 0
    sed -i 's/^SELINUX=.*$/SELINUX=disabled/' /etc/selinux/config
    # remove the conflicting packages
    INFO_MSG " Removing the conflicting packages ..... "
    if [ "${CentOS_RHEL_version:?}" == '8' ]; then
        dnf -y --enablerepo=PowerTools install chrony oniguruma-devel rpcgen
        systemctl enable chronyd
    elif [ "${CentOS_RHEL_version}" == '7' ]; then
        yum -y groupremove "Basic Web Server" "MySQL Database server" "MySQL Database client" "File and Print Server"
        systemctl mask firewalld.service
        INFO_MSG "Check for existing mariadb packages ..... "
        OLDMYSQLSERVER=$(rpm -qa | grep 'mariadb-server' | head -n1)
        if [ -n "$OLDMYSQLSERVER" ]; then
            echo "rpm -e --nodeps $OLDMYSQLSERVER"
            rpm -e --nodeps "$OLDMYSQLSERVER"
        fi
        INFO_MSG "Check for existing mariadb-libs package"
        OLDMYSQL_LIBS=$(rpm -qa | grep 'mariadb-libs' | head -n1)
        if [ -n "$OLDMYSQL_LIBS" ]; then
            echo "yum -y remove mariadb-libs"
            yum -y remove mariadb-libs
        fi
        echo "Check for existing MySQL-shared-compat"
        OLDMYSQL_SHAREDCOMPAT=$(rpm -qa | grep 'MySQL-shared-compat' | head -n1)
        if [ -n "$OLDMYSQL_SHAREDCOMPAT" ]; then
            echo "yum -y remove MySQL-shared-compat"
            yum -y remove MySQL-shared-compat
        fi
    elif [ "${CentOS_RHEL_version}" == '6' ]; then
        yum -y groupremove "FTP Server" "PostgreSQL Database client" "PostgreSQL Database server" "MySQL Database server" "MySQL Database client" "Web Server" "Office Suite and Productivity" "E-mail server" "Ruby Support" "Printing client"
    fi
    iptables_flag='y'
    if [ "${CentOS_RHEL_version}" -ge 7 ] >/dev/null 2>&1 && [ "${iptables_flag}" == 'y' ]; then
        yum -y install iptables-services
        # systemctl enable iptables.service
        # systemctl enable ip6tables.service
    fi

    INFO_MSG "Installing dependencies packages ..... "
    yum check-update
    pkgList="deltarpm gcc gcc-c++ make cmake autoconf glibc glibc-devel glib2 glib2-devel \
        bzip2-devel bzip2 curl libcurl-devel net-tools e2fsprogs e2fsprogs-devel krb5-devel \
        openssl openssl-devel python3 python3-devel \
        libidn libidn-devel bison pcre pcre-devel zip unzip chrony sqlite-devel \
        patch bc expect expat-devel rsyslog lsof wget mkpasswd"

    for Package in ${pkgList}; do
        # shellcheck disable=SC2086
        yum -y install ${Package}
    done
    yum -y update bash openssl glibc
    yum -y upgrade
    SOURCE_SCRIPT "${script_dir:?}"/include/devtoolset.sh
    INFO_MSG " Installing devtoolset ....."
    install_devtoolset
    # pip.conf
    [ -f /etc/pip.conf ] && rm -rf /etc/pip.conf
    cp "${script_dir:?}"/config/pip.conf /etc/pip.conf

}

installDepsUbuntu() {
    # Uninstall the conflicting software
    INFO_MSG " Removing the conflicting packages ..... "
    pkgList="apache2 apache2-data apache2-doc apache2-utils apache2.2-common apache2.2-bin apache2-mpm-prefork apache2-mpm-worker mysql-client mysql-server mysql-common libmysqlclient18 php5 php5-common php5-cgi php5-mysql php5-curl php5-gd libmysql* mysql-*"
    for Package in ${pkgList}; do
        # shellcheck disable=SC2086
        apt-get -y remove --purge ${Package}
    done
    dpkg -l | grep ^rc | awk '{print $2}' | xargs dpkg -P

    apt-get autoremove
    INFO_MSG " Installing dependencies packages..... "
    apt-get -y update
    # critical security updates
    grep security /etc/apt/sources.list >/tmp/security.sources.list
    apt-get -y upgrade -o Dir::Etc::SourceList=/tmp/security.sources.list

    # Install needed packages
    pkgList="gcc g++ make cmake autoconf libjpeg8 libjpeg8-dev libpng12-0 libpng12-dev libpng3 libfreetype6 libfreetype6-dev libxml2 libxml2-dev zlib1g zlib1g-dev libc6 libc6-dev libglib2.0-0 libglib2.0-dev bzip2 libzip-dev libbz2-1.0 libncurses5 libncurses5-dev libaio1 libaio-dev numactl libreadline-dev curl libcurl3 libcurl4-openssl-dev e2fsprogs libkrb5-3 libkrb5-dev libltdl-dev libidn11 libidn11-dev openssl libssl-dev libtool libevent-dev re2c libsasl2-dev libxslt1-dev libicu-dev libsqlite3-dev patch vim zip unzip tmux htop bc dc expect libexpat1-dev iptables rsyslog rsync git lsof lrzsz ntpdate wget sysv-rc"
    for Package in ${pkgList}; do
        # shellcheck disable=SC2086
        apt-get -y install ${Package} --force-yes
    done

    if [[ "${Ubuntu_version:?}" =~ ^14$|^15$ ]]; then
        apt-get -y install libcloog-ppl1
        apt-get -y remove bison
        ln -sf /usr/include/freetype2 /usr/include/freetype2/freetype
    elif [ "${Ubuntu_version}" == "13" ]; then
        apt-get -y install bison libcloog-ppl1
    elif [ "${Ubuntu_version}" == "12" ]; then
        apt-get -y install bison libcloog-ppl0
    else
        apt-get -y install bison libcloog-ppl1
    fi
}
installDepsDebian() {

    INFO_MSG " Removing the conflicting packages ..... "
    pkgList="apache2 apache2-data apache2-doc apache2-utils apache2.2-common apache2.2-bin apache2-mpm-prefork apache2-mpm-worker mysql-client mysql-server mysql-common libmysqlclient18 php5 php5-common php5-cgi php5-mysql php5-curl php5-gd libmysql* mysql-*"
    for Package in ${pkgList}; do
        # shellcheck disable=SC2086
        apt-get -y remove --purge ${Package}
    done
    dpkg -l | grep ^rc | awk '{print $2}' | xargs dpkg -P

    apt-get -y update
    INFO_MSG " Installing dependencies packages ..... "
    # critical security updates
    grep security /etc/apt/sources.list >/tmp/security.sources.list
    apt-get -y upgrade -o Dir::Etc::SourceList=/tmp/security.sources.list

    apt-get autoremove

    # Install needed packages
    case "${Debian_version:?}" in
    [6,7])
        pkgList="gcc g++ make cmake autoconf libjpeg8 libjpeg8-dev libjpeg-dev libpng12-0 libpng12-dev libpng3 libfreetype6 libfreetype6-dev libxml2 libxml2-dev zlib1g zlib1g-dev libc6 libc6-dev libglib2.0-0 libglib2.0-dev bzip2 libzip-dev libbz2-1.0 libncurses5 libncurses5-dev libaio1 libaio-dev numactl libreadline-dev curl libcurl3 libcurl4-openssl-dev libcurl4-gnutls-dev e2fsprogs libkrb5-3 libkrb5-dev libltdl-dev libidn11 libidn11-dev openssl libssl-dev libtool libevent-dev bison re2c libsasl2-dev libxslt1-dev libicu-dev locales libcloog-ppl0 patch vim zip unzip tmux htop bc dc expect libexpat1-dev rsync git lsof lrzsz iptables rsyslog cron logrotate ntpdate libsqlite3-dev psmisc wget sysv-rc"
        ;;
    8)
        pkgList="gcc g++ make cmake autoconf libjpeg8 libjpeg62-turbo-dev libjpeg-dev libpng12-0 libpng12-dev libpng3 libfreetype6 libfreetype6-dev libxml2 libxml2-dev zlib1g zlib1g-dev libc6 libc6-dev libglib2.0-0 libglib2.0-dev bzip2 libzip-dev libbz2-1.0 libncurses5 libncurses5-dev libaio1 libaio-dev numactl libreadline-dev curl libcurl3 libcurl4-openssl-dev libcurl4-gnutls-dev e2fsprogs libkrb5-3 libkrb5-dev libltdl-dev libidn11 libidn11-dev openssl libssl-dev libtool libevent-dev bison re2c libsasl2-dev libxslt1-dev libicu-dev locales libcloog-ppl0 patch vim zip unzip tmux htop bc dc expect libexpat1-dev rsync git lsof lrzsz iptables rsyslog cron logrotate ntpdate libsqlite3-dev psmisc wget sysv-rc"
        ;;
    9)
        pkgList="gcc g++ make cmake autoconf libjpeg62-turbo-dev libjpeg-dev libpng-dev libfreetype6 libfreetype6-dev libxml2 libxml2-dev zlib1g zlib1g-dev libc6 libc6-dev libglib2.0-0 libglib2.0-dev bzip2 libzip-dev libbz2-1.0 libncurses5 libncurses5-dev libaio1 libaio-dev numactl libreadline-dev curl libcurl3 libcurl4-openssl-dev libcurl4-gnutls-dev e2fsprogs libkrb5-3 libkrb5-dev libltdl-dev libidn11 libidn11-dev openssl libssl-dev libtool libevent-dev bison re2c libsasl2-dev libxslt1-dev libicu-dev locales libcloog-ppl1 patch vim zip unzip tmux htop bc dc expect libexpat1-dev rsync git lsof lrzsz iptables rsyslog cron logrotate ntpdate libsqlite3-dev psmisc wget sysv-rc"
        ;;
    *)
        echo -e "${CFAILURE}Your system Debian ${Debian_version} are not supported!${CEND}\n"
        kill -9 $$
        ;;
    esac

    for Package in ${pkgList}; do
        # shellcheck disable=SC2086
        apt-get -y install ${Package}
    done
}

installDepsBySrc() {

    if [ "${OS}" == "CentOS" ]; then

        if [ -e "$(cpmmand -v git)" ]; then
            yum -y remove git
        fi
        SOURCE_SCRIPT "${script_dir:?}"/include/git.sh
        install_git
        SOURCE_SCRIPT "${script_dir:?}"/include/zsh.sh
        install_zsh
        SOURCE_SCRIPT "${script_dir:?}"/include/tmux.sh
        install_tmux
        # SOURCE_SCRIPT "${script_dir:?}"/include/python3.sh
        # install_python36
        # shellcheck disable=SC1091
        # source /opt/rh/rh-python36/enable
        SOURCE_SCRIPT "${script_dir:?}"/include/vim.sh
        install_vim
        install_vim_plugin
    else
        INFO_MSG "No need to install software from source packages ....."
    fi

}
