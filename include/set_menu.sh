#!/bin/bash
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @Desc
#----------------------------------------------------------------------------
function main_menu(){
printf "${CGREEN}
######################################################################
# A tool to auto-compile & install tomcat&&jdk&&nginx&&mysql&&redis  #
#                                                                    #
# Author:  lubo  project:  https://github.com/cnlubo/auto_lnmp       #
######################################################################${CEND}
"
cat << EOF
*  `echo -e "$CGREEN  1) Configure      System  "`
*  `echo -e "$CGREEN  2) DataBase       Install "`
*  `echo -e "$CGREEN  3) Web Server     Install "`
*  `echo -e "$CGREEN  4) DevOps Tools   Install "`
*  `echo -e "$CGREEN  5) Quit               "`
EOF
}
#main_menu
