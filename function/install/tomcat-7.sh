#!/bin/bash
# @Author: ak47
# @Date:   2016-02-26 17:01:42
# @Last Modified by:   卢波
# @Last Modified time: 2016-03-11 15:49:29



Install_tomcat-7()
{
    #download
    src_url=http://mirrors.hust.edu.cn/apache/tomcat/tomcat-7/v$tomcat_7_version/bin/apache-tomcat-$tomcat_7_version.tar.gz && Download_src
    src_url=https://archive.apache.org/dist/tomcat/tomcat-7/v$tomcat_7_version/bin/extras//catalina-jmx-remote.jar && Download_src
    # id -u $tomcat_run_user >/dev/null 2>&1
    # [ $? -ne 0 ] && useradd -M -s /bin/bash $tomcat_run_user || { [ -z "`grep ^$tomcat_run_user /etc/passwd | grep '/bin/bash'`" ] && usermod -s /bin/bash $tomcat_run_user; }
    #run_user
    id -u $run_user >/dev/null 2>&1
    [ $? -ne 0 ] && useradd -M -s /bin/bash $run_user || { [ -z "`grep ^$run_user /etc/passwd | grep '/bin/bash'`" ] && usermod -s /bin/bash $run_user; }
    #install
    cd $script_dir/src
    tar xzf apache-tomcat-$tomcat_7_version.tar.gz
    [ ! -d "$tomcat_install_dir" ] && mkdir -p $tomcat_install_dir
    /bin/cp -R apache-tomcat-$tomcat_7_version/* $tomcat_install_dir
    if [ -e "$tomcat_install_dir/conf/server.xml" ];then
        /bin/cp catalina-jmx-remote.jar $tomcat_install_dir/lib
        cd $tomcat_install_dir/lib
        [ ! -d "$tomcat_install_dir/lib/catalina" ] &&  mkdir $tomcat_install_dir/lib/catalina
        cd $tomcat_install_dir/lib/catalina
        jar xf ../catalina.jar
        sed -i 's@^server.info=.*@server.info=Tomcat@' org/apache/catalina/util/ServerInfo.properties
        sed -i 's@^server.number=.*@server.number=7@' org/apache/catalina/util/ServerInfo.properties
        sed -i "s@^server.built=.*@server.built=`date`@" org/apache/catalina/util/ServerInfo.properties
        jar cf ../catalina.jar ./*
        cd ../../bin
        rm -rf $tomcat_install_dir/lib/catalina
        OS_CentOS='yum -y install apr apr-devel'
        OS_Debian_Ubuntu='apt-get -y install libapr1-dev libaprutil1-dev'
        OS_command
        tar xzf tomcat-native.tar.gz
        cd tomcat-native-*-src/jni/native/
        rm -rf /usr/local/apr
        source /etc/profile
        mco="./configure --with-apr=/usr/bin/apr-1-config  --with-java-home=$JAVA_HOME --with-ssl=yes --prefix=$tomcat_install_dir"
        echo -e $mco | bash
        #./configure --with-apr=/usr/bin/apr-1-config  --with-ssl=yes \
        #--prefix=$tomcat_install_dir
        make && make install
        # if [ -d "/usr/local/apr/lib" ];then
        [ $Mem -le 768 ] && Xms_Mem=`expr $Mem / 3` || Xms_Mem=256
cat > $tomcat_install_dir/bin/setenv.sh <<EOF
            JAVA_OPTS='-server -Xms${Xms_Mem}m -Xmx`expr $Mem / 2`m'
            CATALINA_OPTS="-Djava.library.path=/usr/local/apr/lib"
            # -Djava.rmi.server.hostname=$IPADDR
            # -Dcom.sun.management.jmxremote.password.file=\$CATALINA_BASE/conf/jmxremote.password
            # -Dcom.sun.management.jmxremote.access.file=\$CATALINA_BASE/conf/jmxremote.access
            # -Dcom.sun.management.jmxremote.ssl=false"
EOF
        cd ../../../;rm -rf tomcat-native-*
        chmod +x $tomcat_install_dir/bin/*.sh
        /bin/mv $tomcat_install_dir/conf/server.xml{,_bk}
        #cd $oneinstack_dir/src
        #/bin/cp ../config/server.xml $tomcat_install_dir/conf
        cp $script_dir/config/server.xml $tomcat_install_dir/conf
        sed -i "s@/usr/local/tomcat@$tomcat_install_dir@g" $tomcat_install_dir/conf/server.xml

        # if [ ! -e "$nginx_install_dir/sbin/nginx" -a ! -e "$tengine_install_dir/sbin/nginx" -a ! -e "$apache_install_dir/conf/httpd.conf" ];then
        #     if [ "$OS" == 'CentOS' ];then
        #         if [ -z "`grep -w '8080' /etc/sysconfig/iptables`" ];then
        #             iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 8080 -j ACCEPT
        #         fi
        #     elif [ $OS == 'Debian' -o $OS == 'Ubuntu' ];then
        #         if [ -z "`grep -w '8080' /etc/iptables.up.rules`" ];then
        #             iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 8080 -j ACCEPT
        #         fi
        #     fi
        #     OS_CentOS='service iptables save'
        #     OS_Debian_Ubuntu='iptables-save > /etc/iptables.up.rules'
        #     OS_command
        # fi
        [ ! -d "$tomcat_install_dir/conf/vhost" ] && mkdir $tomcat_install_dir/conf/vhost
            cat > $tomcat_install_dir/conf/vhost/localhost.xml <<EOF
<Host name="localhost" appBase="webapps" unpackWARs="true" autoDeploy="true">
<Context path="" docBase="$wwwroot_dir/default" debug="0" reloadable="false" crossContext="true"/>
<Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
prefix="localhost_access_log." suffix=".txt" pattern="%h %l %u %t &quot;%r&quot; %s %b" />
</Host>
EOF
        #        logrotate tomcat catalina.out
        # cat > /etc/logrotate.d/tomcat <<EOF
        # $tomcat_install_dir/logs/catalina.out {
        # daily
        # rotate 5
        # missingok
        # dateext
        # compress
        # notifempty
        # copytruncate
        # }
        # EOF
        [ -z "`grep '<user username="admin" password=' $tomcat_install_dir/conf/tomcat-users.xml`" ] && sed -i "s@^</tomcat-users>@<role rolename=\"admin-gui\"/>\n<role rolename=\"admin-script\"/>\n<role rolename=\"manager-gui\"/>\n<role rolename=\"manager-script\"/>\n<user username=\"admin\" password=\"`cat /dev/urandom | head -1 | md5sum | head -c 10`\" roles=\"admin-gui,admin-script,manager-gui,manager-script\"/>\n</tomcat-users>@" $tomcat_install_dir/conf/tomcat-users.xml

cat > $tomcat_install_dir/conf/jmxremote.access<<EOF
    monitorRole   readonly
    controlRole   readwrite \
                  create javax.management.monitor.*,javax.management.timer.* \
                  unregister
EOF
cat > $tomcat_install_dir/conf/jmxremote.password <<EOF
    monitorRole  `cat /dev/urandom | head -1 | md5sum | head -c 8`
    # controlRole   R&D
EOF
        mkdir -p $tomcat_install_dir/init.d
        chown -R $run_user.$run_user $tomcat_install_dir
        cp $script_dir/init.d/Tomcat-init $tomcat_install_dir/init.d/tomcat7
        sed -i "s@JAVA_HOME=.*@JAVA_HOME=$JAVA_HOME@" $tomcat_install_dir/init.d/tomcat7
        sed -i "s@^CATALINA_HOME=.*@CATALINA_HOME=$tomcat_install_dir@" $tomcat_install_dir/init.d/tomcat7
        sed -i "s@^TOMCAT_USER=.*@TOMCAT_USER=$run_user@" $tomcat_install_dir/init.d/tomcat7
        # OS_CentOS='chkconfig --add tomcat \n
        # chkconfig tomcat on'
        # OS_Debian_Ubuntu='update-rc.d tomcat defaults'
        # OS_command
        echo "${CSUCCESS}Tomcat install successfully! ${CEND}"
        # fi
    else
        rm -rf $tomcat_install_dir
        echo "${CFAILURE}Tomcat install failed, Please contact the author! ${CEND}"
        kill -9 $$
    fi
    service tomcat start
    cd $script_dir
}
