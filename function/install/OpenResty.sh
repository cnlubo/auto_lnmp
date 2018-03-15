#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              OpenResty.sh
# @Desc
#----------------------------------------------------------------------------

OpenResty_Dep_Install(){

    # 依赖安装
    #yum -y install readline-devel pcre-devel openssl-devel gcc
    yum -y install libuuid-devel


}

Install_OpenResty(){

    echo -e "${CMSG}[create user and group ]***********************************>>${CEND}\n"

    grep ${run_user:?} /etc/group >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        groupadd $run_user
    fi
    id $run_user >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        useradd -g $run_user  -M -s /sbin/nologin $run_user
    fi

    echo -e "${CMSG}[prepare OpenResty install ]***********************************>>${CEND}\n"
    [ -d ${openresty_install_dir:?} ] && rm -rf ${openresty_install_dir:?}
    cd ${script_dir:?}/src
    # shellcheck disable=SC2034
    src_url=https://openresty.org/download/openresty-${openresty_version:?}.tar.gz
    [ ! -f openresty-${openresty_version:?}.tar.gz ] && Download_src
    [ -d openresty-${openresty_version:?} ] && rm -rf openresty-${openresty_version:?}
    tar xf openresty-${openresty_version:?}.tar.gz
    cd openresty-${openresty_version:?}
    #export LUAJIT_LIB=/usr/local/luajit/lib
    #export LUAJIT_INC=/usr/local/luajit/include/luajit-2.1

    ./configure --prefix=${openresty_install_dir:?} \
        --sbin-path=${openresty_install_dir:?}/sbin/nginx \
        --conf-path=${openresty_install_dir:?}/conf/nginx.conf \
        --error-log-path=${openresty_install_dir:?}/logs/error.log \
        --http-log-path=${openresty_install_dir:?}/logs/access.log \
        --pid-path=${openresty_install_dir:?}/run/nginx.pid  \
        --lock-path=${openresty_install_dir:?}/run/nginx.lock \
        --modules-path=${openresty_install_dir:?}/modules \
        --user=$run_user --group=$run_user \
        --with-http_stub_status_module \
        --with-http_ssl_module \
        --with-http_gzip_static_module \
        --with-http_sub_module \
        --with-http_random_index_module \
        --with-http_addition_module \
        --with-http_realip_module  \
        --with-http_v2_module \
        --with-http_iconv_module \
        --with-stream=dynamic --with-stream_ssl_module \
        --http-client-body-temp-path=${openresty_install_dir:?}/tmp/client/ \
        --http-proxy-temp-path=${openresty_install_dir:?}/tmp/proxy/ \
        --http-fastcgi-temp-path=${openresty_install_dir:?}/tmp/fcgi/ \
        --http-uwsgi-temp-path=${openresty_install_dir:?}/tmp/uwsgi \
        --http-scgi-temp-path=${openresty_install_dir:?}/tmp/scgi \
        --with-ld-opt=" -ljemalloc" \
        --with-openssl=../openssl-${openssl_version:?} \
        --with-pcre=../pcre-${pcre_version:?} --with-pcre-jit \
        --with-zlib=../zlib-${zlib_version:?} \
        --with-luajit \
        --add-dynamic-module=${script_dir:?}/src/ngx_brotli \
        --add-dynamic-module=${script_dir:?}/src/incubator-pagespeed-ngx-${pagespeed_version:?} \
        --add-dynamic-module=${script_dir:?}/src/nginx-ct-${ngx_ct_version:?}


    echo -e "${CMSG}[OpenResty install ........ ]***********************************>>${CEND}\n"
    make -j${CpuProNum:?} && make install
    if [ -e "$openresty_install_dir/conf/nginx.conf" ]; then
        echo -e "${CMSG}[OpenResty installed successfully !!!]***********************************>>${CEND}\n"
        mkdir -p ${openresty_install_dir:?}/tmp/client
        Config_OpenResty
    else
        echo -e "${CFAILURE}[OpenResty install failed, Please Contact the author !!!]*************>>${CEND}\n"
        kill -9 $$
    fi

}

Config_OpenResty(){

    if [ -e $openresty_install_dir/conf/nginx.conf ]; then
        echo -e "${CMSG}[configure Openresty]****************************************************>>${CEND}\n"
        mkdir -p ${openresty_install_dir:?}/conf.d
        mv $openresty_install_dir/conf/nginx.conf $openresty_install_dir/conf/nginx.conf_bak
        cp ${script_dir:?}/template/nginx/openresty_template.conf $openresty_install_dir/conf/nginx.conf
        # 修改配置
        sed -i "s#@run_user#${run_user:?}#g" $openresty_install_dir/conf/nginx.conf
        sed -i "s#@openresty_install_dir#$openresty_install_dir#g" $openresty_install_dir/conf/nginx.conf
        [ -f /etc/logrotate.d/openresty ] && rm -rf cat > /etc/logrotate.d/openresty
        # logrotate  log
        cat > /etc/logrotate.d/openresty << EOF
        $openresty_install_dir/logs/*.log {
          daily
          rotate 5
          missingok
          dateext
          compress
          notifempty
          sharedscripts
          postrotate
            [ -e $openresty_install_dir/run/nginx.pid ] && kill -USR1 \`cat $openresty_install_dir/run/nginx.pid\`
          endscript
        }
EOF
        #启动脚本
        mkdir -p ${openresty_install_dir:?}/init.d
        cp $script_dir/template/init.d/openresty.centos ${openresty_install_dir:?}/init.d/openresty
        chmod 775 ${openresty_install_dir:?}/init.d/openresty
        sed -i "s#^nginx_basedir=.*#nginx_basedir=${openresty_install_dir:?}#1" ${openresty_install_dir:?}/init.d/openresty
        #
        #systemd
        if ( [ $OS == "Ubuntu" ] && [ ${Ubuntu_version:?} -ge 15 ] ) || ( [ $OS == "CentOS" ] && [ ${CentOS_RHEL_version:?} -ge 7 ] );then

            [ -L /lib/systemd/system/openresty.service ]  && systemctl disable openresty.service && rm -f /lib/systemd/system/openresty.service
            cp $script_dir/template/systemd/openresty.service /lib/systemd/system/openresty.service
            sed -i "s#@nginx_basedir#${openresty_install_dir:?}#g" /lib/systemd/system/openresty.service
            systemctl enable openresty.service
            echo -e "${CMSG}[starting Oprenresty ] **************************************************>>${CEND}\n"
            systemctl start openresty.service
            echo -e "${CMSG}[start Openresty OK ] **************************************************>>${CEND}\n"
        else
            [ -L /etc/init.d/openresty ] && rm -f /etc/init.d/openresty
            ln -s ${openresty_install_dir:?}/init.d/openresty /etc/init.d/openresty
            echo -e "${CMSG}[starting Oprenresty ] **************************************************>>${CEND}\n"
            service start openresty
            echo -e "${CMSG}[start Openresty OK ] **************************************************>>${CEND}\n"
        fi

    else
        echo -e "${CFAILURE}[Openresty install failed, Please Contact the author !!!]*************>>${CEND}\n"
        kill -9 $$
    fi

}

OpenResty_Install_Main() {
    Nginx_Var && Nginx_Base_Dep_Install && OpenResty_Dep_Install && Install_OpenResty
}
