#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              Tengine.sh
# @Desc
#----------------------------------------------------------------------------
Tengine_Var() {
    #第二种，准确判断pid的信息，
    #-C 表示的是nginx完整命令，不带匹配的操作
    #--no-header 表示不要表头的数据
    #wc -l 表示计数
    COUNT=$(ps -C nginx --no-header |wc -l)
    #echo "ps -c|方法:"$COUNT
    if [ $COUNT -gt 0 ]
    then
        echo -e "${CWARNING}[Error Nginx  is running please stop !!!!]${CEND}\n" && select_nginx_install
    fi


}
Tengine_Dep_Install(){

    # 依赖安装

    echo -e "${CMSG}[Tengine-${tengine_install_version:?} install begin ]***********************>>${CEND}\n"
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

}

Install_Tengine(){

    echo -e "${CMSG}[step2 create user and group ]***********************************>>${CEND}\n"

    grep ${run_user:?} /etc/group >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        groupadd $run_user
    fi
    id $run_user >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        useradd -g $run_user  -M -s /sbin/nologin $run_user
    fi

    echo -e "${CMSG}[step3 prepare Tengine install ]***********************************>>${CEND}\n"
    [ -d ${tengine_install_dir:?} ] && rm -rf ${tengine_install_dir:?}
    cd ${script_dir:?}/src
    # shellcheck disable=SC2034
    src_url=http://tengine.taobao.org/download/tengine-${tengine_install_version:?}.tar.gz
    [ ! -f nginx-${tengine_install_version:?}.tar.gz ] && Download_src
    [ -d tengine-${tengine_install_version:?} ] && rm -rf tengine-${tengine_install_version:?}
    tar xvf tengine-${tengine_install_version:?}.tar.gz
    cd tengine-${tengine_install_version:?}
    # http_stub_status_module 自带的状态页面 默认关闭

    ./configure --prefix=${tengine_install_dir:?} \
    --sbin-path=${tengine_install_dir:?}/sbin/nginx \
    --conf-path=${tengine_install_dir:?}/conf/nginx.conf \
    --error-log-path=${tengine_install_dir:?}/logs/error.log \
    --http-log-path=${tengine_install_dir:?}/logs/access.log \
    --pid-path=${tengine_install_dir:?}/run/nginx.pid  \
    --lock-path=${tengine_install_dir:?}/run/nginx.lock \
    --user=$run_user --group=$run_user \
    --with-http_stub_status_module --with-http_ssl_module \
    --with-http_gzip_static_module --with-http_sub_module \
    --with-http_random_index_module --with-http_addition_module \
    --with-http_realip_module --with-http_v2_module \
    --with-http_concat_module=shared \
    --with-http_sysguard_module=shared \
    --http-client-body-temp-path=${tengine_install_dir:?}/tmp/client/ \
    --http-proxy-temp-path=${tengine_install_dir:?}/tmp/proxy/ \
    --http-fastcgi-temp-path=${tengine_install_dir:?}/tmp/fcgi/ \
    --http-uwsgi-temp-path=${tengine_install_dir:?}/tmp/uwsgi \
    --http-scgi-temp-path=${tengine_install_dir:?}/tmp/scgi \
    --with-openssl=${script_dir:?}/src/openssl-${openssl_version:?} \
    --with-pcre=${script_dir:?}/src/pcre-$pcre_version --with-pcre-jit \
    --with-jemalloc=${script_dir:?}/src/jemalloc-${jemalloc_version:?} \
    --with-zlib=${script_dir:?}/src/zlib-${zlib_version:?}
    # close debug
    sed -i 's@CFLAGS="$CFLAGS -g"@#CFLAGS="$CFLAGS -g"@' auto/cc/gcc
    #打开UTF8支持
    # sed -i 's@./configure --disable-shared@./configure --disable-shared --enable-utf8 --enable-unicode-properties@' objs/Makefile
    echo -e "${CMSG}[step4 Tengine install ........ ]***********************************>>${CEND}\n"
    make -j${CpuProNum:?} && make install
    if [ -e "$tengine_install_dir/conf/nginx.conf" ]; then
        echo -e "${CMSG}[Tengine installed successfully !!!]***********************************>>${CEND}\n"
        mkdir -p ${tengine_install_dir:?}/tmp/client
    else
        echo -e "${CFAILURE}[Tengine install failed, Please Contact the author !!!]*************>>${CEND}\n"
        kill -9 $$
    fi
}

Config_Tengine(){

    if [ -e $tengine_install_dir/conf/nginx.conf ]; then
        echo -e "${CMSG}[Step5 configure Tengine]***********************************>>${CEND}\n"
        mkdir -p ${tengine_install_dir:?}/conf.d
        mv $tengine_install_dir/conf/nginx.conf $tengine_install_dir/conf/nginx.conf_bak
        cp ${script_dir:?}/template/nginx/tengine_template.conf $tengine_install_dir/conf/nginx.conf
        # 修改配置
        sed -i "s#@run_user#${run_user:?}#g" $tengine_install_dir/conf/nginx.conf
        sed -i "s#@worker_processes#2#g" $tengine_install_dir/conf/nginx.conf
        sed -i "s#@tengine_install_dir#$tengine_install_dir#g" $tengine_install_dir/conf/nginx.conf
        # logrotate nginx log
        cat > /etc/logrotate.d/tengine << EOF
        $tengine_install_dir/logs/*.log {
          daily
          rotate 5
          missingok
          dateext
          compress
          notifempty
          sharedscripts
          postrotate
            [ -e $tengine_install_dir/run/nginx.pid ] && kill -USR1 \`cat $tengine_install_dir/run/nginx.pid\`
          endscript
        }
EOF
        #启动脚本
        mkdir -p ${tengine_install_dir:?}/init.d
        cp $script_dir/template/init.d/tengine.centos ${tengine_install_dir:?}/init.d/tengine
        chmod 775 ${tengine_install_dir:?}/init.d/tengine
        sed -i "s#^nginx_basedir=.*#nginx_basedir=${tengine_install_dir:?}#1" ${tengine_install_dir:?}/init.d/tengine
        #
        #systemd
        if ( [ $OS == "Ubuntu" ] && [ ${Ubuntu_version:?} -ge 15 ] ) || ( [ $OS == "CentOS" ] && [ ${CentOS_RHEL_version:?} -ge 7 ] );then

            [ -L /lib/systemd/system/tengine.service ] && rm -f /lib/systemd/system/tengine.service && systemctl disable tengine.service
            cp $script_dir/template/systemd/tengine.service /lib/systemd/system/tengine.service
            sed -i "s#@nginx_basedir#${tengine_install_dir:?}#g" /lib/systemd/system/tengine.service
            systemctl enable tengine.service
            echo -e "${CMSG}[starting Tengine ] **************************************************>>${CEND}\n"
            systemctl start tengine.service
            echo -e "${CMSG}[start Tengine OK ] **************************************************>>${CEND}\n"
        else
            [ -L /etc/init.d/tengine ] && rm -f /etc/init.d/tengine
            ln -s ${nginx_install_dir:?}/init.d/tengine /etc/init.d/tengine
            echo -e "${CMSG}[starting Tengine ] **************************************************>>${CEND}\n"
            service start tengine
            echo -e "${CMSG}[start Tengine OK ] **************************************************>>${CEND}\n"
        fi

    else
        echo -e "${CFAILURE}[Tengine install failed, Please Contact the author !!!]*************>>${CEND}\n"
        kill -9 $$
    fi
}

Tengine_Install_Main() {
    Tengine_Var && Tengine_Dep_Install && Install_Tengine && Config_Tengine
}