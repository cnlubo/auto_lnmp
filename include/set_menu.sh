#!/bin/bash
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @Desc
#----------------------------------------------------------------------------
function main_menu(){
cat << EOF
*  `echo -e "$CGREEN  1) Configure  System  "`
*  `echo -e "$CGREEN  2) MySql      Install "`
*  `echo -e "$CGREEN  3) Postgresql Install "`
*  `echo -e "$CGREEN  4) Nginx      Install "`
*  `echo -e "$CGREEN  5) Tomcat     Install "`
*  `echo -e "$CGREEN  6) Quit               "`
EOF
}
#main_menu