#!/bin/bash
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @Date:                                   2016-01-30 21:48:44
# @file_name:                              jdk-1.7.sh
# @Last Modified by:   ak47
# @Last Modified time: 2016-02-24 17:52:39
# @Desc                                    jdk 1.7 install
#----------------------------------------------------------------------------

Install-JDK-1-7(){

    openjdk=`java -version 2>&1 | grep "OpenJDK $OS_BIT-Bit" | awk '{print $1}' `
    oraclejdk=`java -version 2>&1 | grep "Java HotSpot(TM)" | awk '{print $2}' `
    VER=`java -version 2>&1 | grep "java version" | awk '{print $3}' | tr -d \" | awk '{split($0, array, ".")} END{print array[2]}'`
    if ([ $OS="Ubuntu" ]);then
        if [ -n $openjdk ]; then
            apt-get -y purge openjdk-$VER-jdk&&apt-get -y purge openjdk-$VER-jre
        fi;
    fi
    # #check jdk is
    #if [ -z 'java -version 2>&1 | grep 'java version' | awk '{print $3}' | tr -d \"' ];then
     if [ -z $VER ];then
        echo "${CMSG}[JDK Install] **************************************************>>${CEND}";
        #download jdk
        JDK_FILE="jdk-`echo $jdk_7_version | awk -F. '{print $2}'`u`echo $jdk_7_version | awk -F_ '{print $NF}'`-linux-$SYS_BIG_FLAG.tar.gz"
        src_url=http://mirrors.linuxeye.com/jdk/$JDK_FILE && Download_src
        JDK_NAME="jdk$jdk_7_version"
        cd $script_dir/src
        [ -d $JDK_NAME ] && rm -rf $JDK_NAME
        tar xzf $JDK_FILE;
        JAVA_dir=/usr/lib/jvm;
        JDK_PATH=$JAVA_dir/$JDK_NAME
        if [ -d "$JDK_NAME" ];then
            [ -d $JDK_PATH ] &&rm -rf $JDK_PATH;
            mv $JDK_NAME $JAVA_dir/;
            chown -Rf root.root $JAVA_dir/;
            #setting
            [ -z "`grep ^'export JAVA_HOME=' /etc/profile`" ] && { [ -z "`grep ^'export PATH=' /etc/profile`" ] && echo  "export JAVA_HOME=$JDK_PATH" >> /etc/profile || sed -i "s@^export PATH=@export JAVA_HOME=$JDK_PATH\nexport PATH=@" /etc/profile; } || sed -i "s@^export JAVA_HOME=.*@export JAVA_HOME=$JDK_PATH@" /etc/profile

            [ -z "`grep ^'export CLASSPATH=' /etc/profile`" ] && sed -i "s@export JAVA_HOME=\(.*\)@export JAVA_HOME=\1\nexport CLASSPATH=\$JAVA_HOME/lib/tools.jar:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib@" /etc/profile

            [ -n "`grep ^'export PATH=' /etc/profile`" -a -z "`grep '$JAVA_HOME/bin' /etc/profile`" ] && sed -i "s@^export PATH=\(.*\)@export PATH=\$JAVA_HOME/bin:\1@" /etc/profile

            [ -z "`grep ^'export PATH=' /etc/profile | grep '$JAVA_HOME/bin'`" ] && echo 'export PATH=$JAVA_HOME/bin:$PATH' >> /etc/profile
            . /etc/profile
            # setting default jdk
            echo "${CMSG}[Setting Default JDK] **************************************************>>${CEND}";
            if ([ $OS="Ubuntu" ]);then
                update-alternatives --install  /usr/bin/java java $JDK_PATH/bin/java 9999
                update-alternatives --install  /usr/bin/jar jar $JDK_PATH/bin/jar 9999
                update-alternatives --install  /usr/bin/javac javac $JDK_PATH/bin/javac 9999
            fi
            echo "${CSUCCESS}$JDK_NAME install successfully! ${CEND}"
        else
            echo "${CFAILURE}JDK install failed, Please contact the author! ${CEND}"
            kill -9 $$
        fi
        cd $script_dir
    else
    JDKVER=`java -version 2>&1 | grep "java version" | awk '{print $3}' | tr -d \" `
    # if [[ $VER ge 7 ]]; then
    #     echo "Java version is greater than 1.7."
    # else
    #     echo "Java version is lower than 1.7."
    # fi;
    #echo $VER
    #echo $VER1
    echo "${CMSG}[JDK version $JDKVER having install] **************************************************>>${CEND}";
fi
}
