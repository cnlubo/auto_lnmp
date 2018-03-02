#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              LuaJIT.sh
# @Desc
#----------------------------------------------------------------------------

Install_LuaJIT() {

    if [ -d /usr/local/luajit ];then
        echo -e "${CMSG}[ LuaJIT has been install !!! ] ****************************>>${CEND}\n"
    else
        echo -e "${CMSG}[ LuaJIT-${LuaJIT_version:?} instal begin ] *********************>>${CEND}\n"
        cd ${script_dir:?}/src
        [ -d luajit-2.0 ] && rm -rf luajit-2.0
        git clone http://luajit.org/git/luajit-2.0.git
        cd luajit-2.0 && git checkout v${LuaJIT_version:?}
        make && make install PREFIX=/usr/local/luajit
        [ -f /etc/ld.so.conf.d/luajit.conf ] && rm -rf /etc/ld.so.conf.d/luajit.conf
#         cat > /etc/ld.so.conf.d/luajit.conf << EOF
# /usr/local/luajit/lib
# EOF
        echo "/usr/local/luajit/lib" > /etc/ld.so.conf.d/luajit.conf && ldconfig -V
        if [ $? -eq 0 ];then
            echo "${CMSG} [ LuaJIT-${LuaJIT_version:?} install success ! ] **********************************>>${CEND}"
        else
            echo "${CFAILURE}[ LuaJIT-${LuaJIT_version:?} install failed, Please contact the author !!!] ****************************>>${CEND}"
            kill -9 $$
        fi
    fi
}
