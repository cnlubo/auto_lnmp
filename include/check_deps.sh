#!/bin/bash
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @Desc                                    install  packages and software
#----------------------------------------------------------------------------

installDepsCentOS() {

    #sed -i 's@^exclude@#exclude@' /etc/yum.conf #注释exclude
    echo "${CMSG} install yum-fastestmirror epel-release...${CEND}"
    yum -y install yum-fastestmirror epel-release
    yum clean all
    yum makecache

    # Uninstall the conflicting packages
    echo "${CMSG}Removing the conflicting packages...${CEND}"
    if [ "${CentOS_RHEL_version}" == '7' ]; then
        yum -y groupremove "Basic Web Server" "MySQL Database server" "MySQL Database client" "File and Print Server"
        systemctl mask firewalld.service
        yum -y install iptables-services net-tools
        # systemctl enable iptables.service
    elif [ "${CentOS_RHEL_version}" == '6' ]; then
        yum -y groupremove "FTP Server" "PostgreSQL Database client" "PostgreSQL Database server" "MySQL Database server" "MySQL Database client" "Web Server" "Office Suite and Productivity" "E-mail server" "Ruby Support" "Printing client"
    elif [ "${CentOS_RHEL_version}" == '5' ]; then
        yum -y groupremove "FTP Server" "Windows File Server" "PostgreSQL Database" "News Server" "MySQL Database" "DNS Name Server" "Web Server" "Dialup Networking Support" "Mail Server" "Ruby" "Office/Productivity" "Sound and Video" "Printing Support" "OpenFabrics Enterprise Distribution"
    fi
    echo "${CMSG}Installing dependencies packages...${CEND}"
    yum check-update
    # Install needed packages
    #pkgList="deltarpm gcc gcc-c++ make cmake autoconf libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel ncurses ncurses-devel libaio numactl numactl-libs readline-devel curl curl-devel e2fsprogs e2fsprogs-devel krb5-devel libidn libidn-devel openssl openssl-devel libxslt-devel libicu-devel libevent-devel libtool libtool-ltdl bison gd-devel vim-enhanced pcre-devel zip unzip ntpdate sqlite-devel sysstat patch bc expect expat-devel rsync rsyslog git lsof lrzsz wget net-tools"

    pkgList="deltarpm gcc gcc-c++ make cmake autoconf glibc glibc-devel glib2 glib2-devel \
    bzip2-devel curl libcurl-devel e2fsprogs e2fsprogs-devel krb5-devel openssl openssl-devel \
    libidn libidn-devel bison pcre pcre-devel zip unzip ntpdate sqlite-devel \
    patch bc expect expat-devel rsyslog lsof wget net-tools"

    for Package in ${pkgList}; do
        yum -y install ${Package}
    done
    yum -y update bash openssl glibc
    yum -y upgrade
    # centos devtoolset
    # devtoolset-3(gcc-4.9.2)、devtoolset-4(gcc-5.2.1)
    echo "${CMSG}Installing centos devtoolset3(gcc-4.9.2)...${CEND}"
    yum -y install scl-utils
    if [ "$CentOS_RHEL_version" == '7' ];then
        rpm -ivh "https://www.softwarecollections.org/repos/rhscl/devtoolset-3/epel-7-x86_64/noarch/rhscl-devtoolset-3-epel-7-x86_64-1-2.noarch.rpm"
    elif [ "$CentOS_RHEL_version" == '6' ];then
        rpm -ivh "https://www.softwarecollections.org/repos/rhscl/devtoolset-3/epel-6-x86_64/noarch/rhscl-devtoolset-3-epel-6-x86_64-1-2.noarch.rpm"
    fi
    yum -y install devtoolset-3-gcc devtoolset-3-gcc-c++ devtoolset-3-gdb

}

installDepsUbuntu() {
    # Uninstall the conflicting software
    echo "${CMSG}Removing the conflicting packages...${CEND}"
    pkgList="apache2 apache2-data apache2-doc apache2-utils apache2.2-common apache2.2-bin apache2-mpm-prefork apache2-mpm-worker mysql-client mysql-server mysql-common libmysqlclient18 php5 php5-common php5-cgi php5-mysql php5-curl php5-gd libmysql* mysql-*"
    for Package in ${pkgList}; do
        apt-get -y remove --purge ${Package}
    done
    dpkg -l | grep ^rc | awk '{print $2}' | xargs dpkg -P

    apt-get autoremove

    echo "${CMSG}Installing dependencies packages...${CEND}"
    apt-get -y update
    # critical security updates
    grep security /etc/apt/sources.list > /tmp/security.sources.list
    apt-get -y upgrade -o Dir::Etc::SourceList=/tmp/security.sources.list

    # Install needed packages
    pkgList="gcc g++ make cmake autoconf libjpeg8 libjpeg8-dev libpng12-0 libpng12-dev libpng3 libfreetype6 libfreetype6-dev libxml2 libxml2-dev zlib1g zlib1g-dev libc6 libc6-dev libglib2.0-0 libglib2.0-dev bzip2 libzip-dev libbz2-1.0 libncurses5 libncurses5-dev libaio1 libaio-dev numactl libreadline-dev curl libcurl3 libcurl4-openssl-dev e2fsprogs libkrb5-3 libkrb5-dev libltdl-dev libidn11 libidn11-dev openssl libssl-dev libtool libevent-dev re2c libsasl2-dev libxslt1-dev libicu-dev libsqlite3-dev patch vim zip unzip tmux htop bc dc expect libexpat1-dev iptables rsyslog rsync git lsof lrzsz ntpdate wget sysv-rc"
    for Package in ${pkgList}; do
        apt-get -y install ${Package} --force-yes
    done

    if [[ "${Ubuntu_version}" =~ ^14$|^15$ ]]; then
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
    echo "${CMSG}Removing the conflicting packages...${CEND}"
    pkgList="apache2 apache2-data apache2-doc apache2-utils apache2.2-common apache2.2-bin apache2-mpm-prefork apache2-mpm-worker mysql-client mysql-server mysql-common libmysqlclient18 php5 php5-common php5-cgi php5-mysql php5-curl php5-gd libmysql* mysql-*"
    for Package in ${pkgList};do
        apt-get -y remove --purge ${Package}
    done
    dpkg -l | grep ^rc | awk '{print $2}' | xargs dpkg -P

    apt-get -y update
    echo "${CMSG}Installing dependencies packages...${CEND}"
    # critical security updates
    grep security /etc/apt/sources.list > /tmp/security.sources.list
    apt-get -y upgrade -o Dir::Etc::SourceList=/tmp/security.sources.list

    apt-get autoremove

    # Install needed packages
    case "${Debian_version}" in
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
            echo "${CFAILURE}Your system Debian ${Debian_version} are not supported!${CEND}"
            kill -9 $$
        ;;
    esac

    for Package in ${pkgList}; do
        apt-get -y install ${Package}
    done
}


installDepsBySrc() {


    # pushd ${oneinstack_dir}/src
    #
    # if [ "${OS}" == "Ubuntu" ]; then
    #     if [[ "${Ubuntu_version}" =~ ^14$|^15$ ]]; then
    #         # Install bison on ubt 14.x 15.x
    #         tar xzf bison-${bison_version}.tar.gz
    #         pushd bison-${bison_version}
    #         ./configure
    #         make -j ${THREAD} && make install
    #         popd
    #         rm -rf bison-${bison_version}
    #     fi
    # elif [ "${OS}" == "CentOS" ]; then
    #     # Install tmux
    #     if [ ! -e "$(which tmux)" ]; then
    #         # Install libevent first
    #         tar xzf libevent-${libevent_version}.tar.gz
    #         pushd libevent-${libevent_version}
    #         ./configure
    #         make -j ${THREAD} && make install
    #         popd
    #         rm -rf libevent-${libevent_version}
    #
    #         tar xzf tmux-${tmux_version}.tar.gz
    #         pushd tmux-${tmux_version}
    #         CFLAGS="-I/usr/local/include" LDFLAGS="-L/usr/local/lib" ./configure
    #         make -j ${THREAD} && make install
    #         unset LDFLAGS
    #         popd
    #         rm -rf tmux-${tmux_version}
    #
    #         if [ "${OS_BIT}" == "64" ]; then
    #             ln -s /usr/local/lib/libevent-2.0.so.5 /usr/lib64/libevent-2.0.so.5
    #         else
    #             ln -s /usr/local/lib/libevent-2.0.so.5 /usr/lib/libevent-2.0.so.5
    #         fi
    #     fi
    #
    #     # install htop
    #     if [ ! -e "$(which htop)" ]; then
    #         tar xzf htop-${htop_version}.tar.gz
    #         pushd htop-${htop_version}
    #         ./configure
    #         make -j ${THREAD} && make install
    #         popd
    #         rm -rf htop-${htop_version}
    #     fi
    # else
    #     echo "No need to install software from source packages."
    # fi
    # popd
    #
    #
    if [ "${OS}" == "CentOS" ]; then
        # git
        yum -y remove git
        src_url=https://www.kernel.org/pub/software/scm/git/git-$git_version.tar.gz
        Download_src
        cd $script_dir/src
        tar xvf git-$git_version.tar.gz
        cd git-$git_version
        # 安装依赖
        yum -y install gcc openssl-devel curl-devel expat-devel perl-devel
        make prefix=/usr/local/git all
        make prefix=/usr/local/git install
        ln -s /usr/local/git/bin/* /usr/bin/
        cd ..
        rm -rf git-$git_version
        # tmux
        if [ ! -e "$(which tmux)" ]; then
            yum -y install ncurses-devel automake
            # Install libevent first
            src_url=https://github.com/libevent/libevent/releases/download/release-$libevent_version/libevent-$libevent_version.tar.gz
            Download_src
            cd $script_dir/src
            tar xzf libevent-${libevent_version}.tar.gz
            cd  libevent-${libevent_version}
            ./configure
            make && make install
            cd ..
            rm -rf libevent-${libevent_version}
            #
            git clone https://github.com/tmux/tmux.git
            cd tmux
            sh autogen.sh
            CFLAGS="-I/usr/local/include" LDFLAGS="-L/usr/local/lib" ./configure
            make && make install
            unset LDFLAGS
            cd ..
            rm -rf tmux
            if [ "${OS_BIT}" == "64" ]; then
                ln -s /usr/local/lib/libevent-2.1.so.6 /usr/lib64/libevent-2.1.so.6
            else
                ln -s /usr/local/lib/libevent-2.1.so.6 /usr/lib/libevent-2.1.so.6
            fi
        fi
        # update python
        src_url=https://www.python.org/ftp/python/$python2_version/Python-$python2_version.tar.xz
        Download_src
        tar xvf Python-$python2_version.tar.xz&&cd Python-$python2_version
        # 安装依赖
        yum -y install  openssl-devel ncurses-devel  bzip2-devel sqlite-devel readline-devel zlib-devel  tk-devel gdbm-devel
        mkdir -p /usr/local/python$python2_version/lib
        ./configure --enable-shared  --enable-unicode=ucs4 --prefix=/usr/local/python$python2_version LDFLAGS="-Wl,-rpath /usr/local/python$python2_version/lib"
        make&&make install
        cd ..
        rm -rf Python-$python2_version
        # 替换默认python
        mkdir -p /usr/bin/backup_python
        if [ "${CentOS_RHEL_version}" == '7' ]; then
            mv /usr/bin/python2.7 /usr/bin/python2.7.5
            cp /usr/bin/python2.7.5 /usr/bin/backup_python
            ln -s /usr/local/python$python2_version/bin/python2.7 /usr/bin/python2.7
            # 修改 /usr/bin/yum和/usr/libexec/urlgrabber-ext-down的Python版本
            sed -i "s@^#\!/usr/bin/python.*@#\!  /usr/bin/python2.7.5@" /usr/bin/yum
            sed -i "s@^#\!/usr/bin/python.*@#\!  /usr/bin/python2.7.5@" /usr/libexec/urlgrabber-ext-down
            # pip setuptools
            src_url=https://github.com/pypa/setuptools/archive/v$setuptools_version.tar.gz&&Download_src
            src_url=https://github.com/pypa/pip/archive/$pip_version.tar.gz&&Download_src
            tar xvf $pip_version.tar.gz&&tar xvf v$setuptools_version.tar.gz
            cd setuptools-$setuptools_version
            python bootstrap.py&&python setup.py install&&cd ..
            cd pip-$pip_version
            python setup.py install
            cd ..
            rm -rf setuptools-$setuptools_version
            rm -rf pip-$pip_version
        fi
        # zsh
        if [ ! -e "$(which zsh)" ]; then
            yum -y install ncurses-devel
            src_url=https://sourceforge.net/projects/zsh/files/zsh/$zsh_version/zsh-$zsh_version.tar.gz/download
            Download_src&&mv download zsh-$zsh_version.tar.gz&&tar xvf zsh-$zsh_version.tar.gz
            cd zsh-$zsh_version
            ./configure&&make&&make install
            cd ..
            rm -rf zsh-$zsh_version
        fi
        # vim
        cd $script_dir/src
        yum -y install ncurses-devel perl-ExtUtils-Embed luajit luajit-devel lua-devel
        git clone https://github.com/vim/vim.git
        cd vim
        ./configure --prefix=/usr/local/vim --with-features=huge --enable-gui=gtk2 \
        --enable-fontset --enable-multibyte --enable-pythoninterp \
        --with-python-config-dir=/usr/local/python$python2_version/lib/python2.7/config \
        --enable-perlinterp --enable-rubyinterp --enable-luainterp --enable-cscope --enable-xim --with-x  --with-luajit
        make CFLAGS="-O2 -D_FORTIFY_SOURCE=1"&&make install
        ln -s /usr/local/vim/bin/vim /usr/local/bin/vim
        cd ..
        rm -rf vim

    elif [ "${OS}" == "Ubuntu" ]; then
        # Install tmux


        # install htop
        if [ ! -e "$(which htop)" ]; then
            tar xzf htop-${htop_version}.tar.gz
            pushd htop-${htop_version}
            ./configure
            make -j ${THREAD} && make install
            popd
            rm -rf htop-${htop_version}
        fi
    else
        echo "No need to install software from source packages."
    fi


}
