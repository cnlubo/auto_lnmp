#!/bin/bash
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @Desc
#----------------------------------------------------------------------------

#function main_menu(){
#cat << EOF
#----------------------------------------------
#|***************** Main Menu ****************|
#----------------------------------------------
#*   `echo -e "\033[36m 1) Configure   \033[0m"`
#*   `echo -e "\033[36m 2) mysql       \033[0m"`
#*   `echo -e "\033[36m 3) postgresql  \033[0m"`
#*   `echo -e "\033[36m 4) nginx       \033[0m"`
#*   `echo -e "\033[36m 5) tomcat      \033[0m"`
#*   `echo -e "\033[36m 6) quit        \033[0m"`
#EOF
#}
function main_menu(){
cat << EOF
*   `echo -e "$CGREEN  1) Configure "`
*   `echo -e "\033[36m 2) mysql       \033[0m"`
*   `echo -e "\033[36m 3) postgresql  \033[0m"`
*   `echo -e "\033[36m 4) nginx       \033[0m"`
*   `echo -e "\033[36m 5) tomcat      \033[0m"`
*   `echo -e "\033[36m 6) quit        \033[0m"`
EOF
}
#main_menu