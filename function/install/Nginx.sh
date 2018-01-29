#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              Nginx.sh
# @Desc
#----------------------------------------------------------------------------
Nginx_Var() {
    echo ${nginx_install_version:?}
}
Nginx_Dependence_Install(){

    # 依赖安装

    echo -e "${CMSG}[nginx-${nginx_install_version:?} install begin ]***********************>>${CEND}\n"
    echo -e "${CMSG}[step1 zlib pcre jemalloc openssl ]***********************************>>${CEND}\n"
    cd ${script_dir:?}/src
    # zlib
    # shellcheck disable=SC2034
    src_url=http://zlib.net/zlib-${zlib_version:?}.tar.gz
    [ ! -f zlib-${zlib_version:?}.tar.gz ] && Download_src
    [ -d zlib-${zlib_version:?} ] && rm -rf zlib-${zlib_version:?}
    tar xvf zlib-${zlib_version:?}.tar.gz
    # && cd zlib-${zlib_version:?}
    # ./configure --prefix=/usr/local/software/sharelib && make && make install
    # cd ..
    # pcre
    # shellcheck disable=SC2034
    src_url=https://sourceforge.net/projects/pcre/files/pcre/${pcre_version:?}/pcre-$pcre_version.tar.gz/download
    [ ! -f pcre-$pcre_version.tar.gz ] && Download_src && mv download pcre-$pcre_version.tar.gz
    [ -d pcre-$pcre_version ] && rm -rf pcre-$pcre_version
    tar xvf pcre-$pcre_version.tar.gz
    # && cd pcre-$pcre_version
    # ./configure --prefix=/usr/local/software/pcre --enable-utf8 --enable-unicode-properties
    # make && make install
    # cd ..
    #
    # openssl
    # shellcheck disable=SC2034
    src_url=https://www.openssl.org/source/openssl-${openssl_version:?}.tar.gz
    [ ! -f openssl-${openssl_version:?}.tar.gz ] && Download_src
    [ -d openssl-${openssl_version:?} ] && rm -rf openssl-${openssl_version:?}
    tar xvf openssl-${openssl_version:?}.tar.gz
    # jemalloc
    SOURCE_SCRIPT ${script_dir:?}/include/jemalloc.sh
    Install_Jemalloc
    # other
    yum -y install gcc automake autoconf libtool make gcc-c++
    # ngx_brotli
    echo -e "${CMSG}[step2 support ngx_brotli ]***********************************>>${CEND}\n"
    cd ${script_dir:?}/src
    [ -d ngx_brotli ] && rm -rf ngx_brotli
    git clone https://github.com/google/ngx_brotli.git
    cd ngx_brotli && git submodule update --init


}
Install_Nginx(){

    echo -e "${CMSG}[step3 create user and group ]***********************************>>${CEND}\n"

    grep ${run_user:?} /etc/group >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        groupadd $run_user
    fi
    id $run_user >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        useradd -g $run_user  -M -s /sbin/nologin $run_user
    fi

    echo -e "${CMSG}[step4 prepare nginx install ]***********************************>>${CEND}\n"
    [ -d ${nginx_install_dir:?} ] && rm -rf ${nginx_install_dir:?}
    cd ${script_dir:?}/src
    # shellcheck disable=SC2034
    src_url=https://nginx.org/download/nginx-${nginx_install_version:?}.tar.gz
    [ ! -f nginx-${nginx_install_version:?}.tar.gz ] && Download_src
    [ -d nginx-${nginx_install_version:?} ] && rm -rf nginx-${nginx_install_version:?}
    tar xvf nginx-${nginx_install_version:?}.tar.gz
    cd nginx-${nginx_install_version:?}
    ./configure --prefix=${nginx_install_dir:?} \
    --sbin-path=${nginx_install_dir:?}/sbin/nginx \
    --conf-path=${nginx_install_dir:?}/conf/nginx.conf \
    --error-log-path=${nginx_install_dir:?}/logs/error.log \
    --http-log-path=${nginx_install_dir:?}/logs/access.log \
    --pid-path=${nginx_install_dir:?}/run/nginx.pid  \
    --lock-path=${nginx_install_dir:?}/run/nginx.lock \
    --user=$run_user --group=$run_user --with-http_stub_status_module \
    --with-http_ssl_module --with-http_gzip_static_module \
    --with-http_sub_module --with-http_random_index_module \
    --with-http_addition_module --with-http_realip_module   \
    --http-client-body-temp-path=${nginx_install_dir:?}/tmp/client/ \
    --http-proxy-temp-path=${nginx_install_dir:?}/tmp/proxy/ \
    --http-fastcgi-temp-path=${nginx_install_dir:?}/tmp/fcgi/ \
    --http-uwsgi-temp-path=${nginx_install_dir:?}/tmp/uwsgi \
    --http-scgi-temp-path=${nginx_install_dir:?}/tmp/scgi \
    --with-ld-opt="-ljemalloc" --with-openssl=${script_dir:?}/src/openssl-${openssl_version:?} \
    --with-pcre=${script_dir:?}/src/pcre-$pcre_version --with-pcre-jit --with-http_v2_module \
    --add-module=${script_dir:?}/src/ngx_brotli  --with-zlib=${script_dir:?}/src/zlib-${zlib_version:?}
    # close debug
    sed -i 's@CFLAGS="$CFLAGS -g"@#CFLAGS="$CFLAGS -g"@' auto/cc/gcc
    #打开UTF8支持
    sed -i 's@./configure --disable-shared@./configure --disable-shared --enable-utf8 --enable-unicode-properties@' objs/Makefile
    echo -e "${CMSG}[step5 nginx install ........ ]***********************************>>${CEND}\n"
    make -j${CpuProNum:?} && make install
    if [ -e "$nginx_install_dir/conf/nginx.conf" ]; then
        echo -e "${CMSG}[Nginx installed successfully !!!]***********************************>>${CEND}\n"
        mkdir -p ${nginx_install_dir:?}/tmp/client
    else
        echo -e "${CFAILURE}[Nginx install failed, Please Contact the author !!!]*************>>${CEND}\n"
        kill -9 $$
    fi
}

Config_Nginx(){

    if [ -e $nginx_install_dir/conf/nginx.conf ]; then
        echo -e "${CMSG}[Step6 configure nginx]***********************************>>${CEND}\n"
        mkdir -p ${nginx_install_dir:?}/conf.d
        mv $nginx_install_dir/conf/nginx.conf $nginx_install_dir/conf/nginx.conf_bak
        cp ${script_dir:?}/template/nginx/nginx_template.conf $nginx_install_dir/conf/nginx.conf
        # 修改配置
        # sed -i "s@^###user.*@user          $run_user    $run_user;@" $nginx_install_dir/conf/nginx.conf
        # sed -i "s@^###worker_processes.*@worker_processes     2;@" $nginx_install_dir/conf/nginx.conf
        # sed -i "s@^###include.*@include  ${nginx_install_dir:?}/conf.d;@" $nginx_install_dir/conf/nginx.conf
        sed -i "s#@run_user#${run_user:?}#g" $nginx_install_dir/conf/nginx.conf
        sed -i "s#@worker_processes#2#g" $nginx_install_dir/conf/nginx.conf
        sed -i "s#@nginx_install_dir#$nginx_install_dir#g" $nginx_install_dir/conf/nginx.conf
        # logrotate nginx log
        cat > /etc/logrotate.d/nginx << EOF
        $nginx_install_dir/logs/*.log {
          daily
          rotate 5
          missingok
          dateext
          compress
          notifempty
          sharedscripts
          postrotate
            [ -e $nginx_install_dir/run/nginx.pid ] && kill -USR1 \`cat $nginx_install_dir/run/nginx.pid\`
          endscript
        }
EOF
        #启动脚本
        mkdir -p ${nginx_install_dir:?}/init.d
        cp $script_dir/template/nginx.centos ${nginx_install_dir:?}/init.d/nginx
        chmod 775 ${nginx_install_dir:?}/init.d/nginx
        sed -i "s#^nginx_basedir=.*#nginx_basedir=${nginx_install_dir:?}#1" ${nginx_install_dir:?}/init.d/nginx
        # sed  -i ':a;$!{N;ba};s#nginx_basedir=#nginx_basedir='''${nginx_install_dir:?}'''#' ${nginx_install_dir:?}/init.d/nginx
        #
        #systemd
        if ( [ $OS == "Ubuntu" ] && [ ${Ubuntu_version:?} -ge 15 ] ) || ( [ $OS == "CentOS" ] && [ ${CentOS_RHEL_version:?} -ge 7 ] );then

            [ -L /lib/systemd/system/nginx.service ] && rm -f /lib/systemd/system/nginx.service
            cp $script_dir/template/systemd/nginx.service /lib/systemd/system/nginx.service
            sed -i "s#@nginx_basedir#${nginx_install_dir:?}#g" /lib/systemd/system/nginx.service
            systemctl enable nginx.service
            echo -e "${CMSG}[starting nginx ] **************************************************>>${CEND}\n"
            systemctl start nginx.service
        else
            [ -L /etc/init.d/nginx ] && rm -f /etc/init.d/nginx
            ln -s ${nginx_install_dir:?}/init.d/nginx /etc/init.d/nginx
            echo -e "${CMSG}[starting nginx ] **************************************************>>${CEND}\n"
            service start nginx
        fi

    else
        echo -e "${CFAILURE}[Nginx install failed, Please Contact the author !!!]*************>>${CEND}\n"
        kill -9 $$
    fi
}

Nginx_Install_Main() {
    Nginx_Dependence_Install && Install_Nginx && Config_Nginx
}
