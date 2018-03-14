#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              Tengine.sh
# @Desc
#----------------------------------------------------------------------------

Tengine_Dep_Install(){

    echo -e "${CMSG}[ Openssl-${openssl_latest_version:?} ]***********************************>>${CEND}\n"
    # openssl
    # shellcheck disable=SC2034
    cd ${script_dir:?}/src
    src_url=https://www.openssl.org/source/openssl-${openssl_latest_version:?}.tar.gz
    [ ! -f openssl-${openssl_latest_version:?}.tar.gz ] && Download_src
    [ -d openssl-${openssl_latest_version:?} ] && rm -rf openssl-${openssl_latest_version:?}
    tar xf openssl-${openssl_latest_version:?}.tar.gz



}

Install_Tengine(){

    echo -e "${CMSG}[create user and group ]***********************************>>${CEND}\n"

    grep ${run_user:?} /etc/group >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        groupadd $run_user
    fi
    id $run_user >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        useradd -g $run_user  -M -s /sbin/nologin $run_user
    fi

    echo -e "${CMSG}[prepare Tengine install ]***********************************>>${CEND}\n"
    [ -d ${tengine_install_dir:?} ] && rm -rf ${tengine_install_dir:?}
    cd ${script_dir:?}/src
    # shellcheck disable=SC2034
    src_url=http://tengine.taobao.org/download/tengine-${tengine_install_version:?}.tar.gz
    [ ! -f nginx-${tengine_install_version:?}.tar.gz ] && Download_src
    [ -d tengine-${tengine_install_version:?} ] && rm -rf tengine-${tengine_install_version:?}
    tar xf tengine-${tengine_install_version:?}.tar.gz
    cd tengine-${tengine_install_version:?}
    # http_stub_status_module 自带的状态页面 默认关闭
    # ./configure --user=nginx --group=nginx --with-file-aio --with-ipv6
    # --with-http_spdy_module --with-http_v2_module
    # --with-http_realip_module
    # --with-http_addition_module=shared --with-http_sub_module=shared --with-http_dav_module --with-http_flv_module=shared --with-http_slice_module=shared --with-http_mp4_module=shared
    # --with-http_gunzip_module --with-http_gzip_static_module
    #   --with-http_auth_request_module
    #   --with-http_concat_module=shared --with-http_random_index_module=shared
    #   --with-http_secure_link_module=shared --with-http_degradation_module
    #   --with-http_sysguard_module=shared --with-http_dyups_module
    #   --with-mail --with-mail_ssl_module --with-jemalloc

    if [ ${lua_install:?} = 'y' ]; then
        #nginx_modules_options="--with-ld-opt='-Wl,-rpath,/usr/local/luajit/lib' --add-module=${script_dir:?}/src/ngx_devel_kit-${ngx_devel_kit_version:?} --add-module=${script_dir:?}/src/lua-nginx-module-${lua_nginx_module_version:?}"
        export LUAJIT_LIB=/usr/local/luajit/lib
        export LUAJIT_INC=/usr/local/luajit/include/luajit-2.1
        nginx_modules_options="--with-ld-opt='-Wl,-rpath,/usr/local/luajit/lib'"
        nginx_modules_options=$nginx_modules_options" --with-http_lua_module=shared"
        nginx_modules_options=$nginx_modules_options" --add-dynamic-module=../ngx_devel_kit-${ngx_devel_kit_version:?}"
        # 替换lua-nginx-module 代码为最新版本
        mv modules/ngx_http_lua_module modules/ngx_http_lua_module_old
        cp -ar ${script_dir:?}/src/lua-nginx-module-${lua_nginx_module_version:?} modules/ngx_http_lua_module
    else
        nginx_modules_options=''
    fi

    ./configure --prefix=${tengine_install_dir:?} \
        --sbin-path=${tengine_install_dir:?}/sbin/nginx \
        --conf-path=${tengine_install_dir:?}/conf/nginx.conf \
        --error-log-path=${tengine_install_dir:?}/logs/error.log \
        --http-log-path=${tengine_install_dir:?}/logs/access.log \
        --pid-path=${tengine_install_dir:?}/run/nginx.pid  \
        --lock-path=${tengine_install_dir:?}/run/nginx.lock \
        --user=$run_user --group=$run_user \
        --with-file-aio \
        --with-http_v2_module \
        --with-http_realip_module \
        --with-http_gzip_static_module \
        --with-http_gunzip_module \
        --with-http_auth_request_module \
        --with-http_degradation_module \
        --with-http_stub_status_module \
        --with-http_ssl_module \
        --with-http_addition_module=shared \
        --with-http_sub_module=shared \
        --with-http_concat_module=shared \
        --with-http_random_index_module=shared \
        --with-http_sysguard_module=shared \
        --http-client-body-temp-path=${tengine_install_dir:?}/tmp/client/ \
        --http-proxy-temp-path=${tengine_install_dir:?}/tmp/proxy/ \
        --http-fastcgi-temp-path=${tengine_install_dir:?}/tmp/fcgi/ \
        --http-uwsgi-temp-path=${tengine_install_dir:?}/tmp/uwsgi \
        --http-scgi-temp-path=${tengine_install_dir:?}/tmp/scgi \
        --with-openssl=../openssl-${openssl_version:?}  \
        --with-pcre=../pcre-${pcre_version:?} --with-pcre-jit \
        --with-jemalloc \
        --with-zlib=../zlib-${zlib_version:?} \
        --add-dynamic-module=../incubator-pagespeed-ngx-${pagespeed_version:?} \
        --add-dynamic-module=../nginx-ct-${ngx_ct_version:?} $nginx_modules_options
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
        if [ ${lua_install:?} = 'y' ]; then
            cp ${script_dir:?}/template/nginx/tengine_lua_template.conf $tengine_install_dir/conf/nginx.conf
        else
            cp ${script_dir:?}/template/nginx/tengine_template.conf $tengine_install_dir/conf/nginx.conf
        fi
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

            [ -L /lib/systemd/system/tengine.service ] && systemctl disable tengine.service && rm -f /lib/systemd/system/tengine.service
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
    Nginx_Var && Nginx_Base_Dep_Install && Tengine_Dep_Install && Install_Tengine && Config_Tengine
}
