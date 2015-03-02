#!/bin/bash
##########################################
# File Name: lasy_setup_ss.sh
# Author: Allan Xing
# Email: xingpeng2012@gmail.com
# Date: 20150301
# Version: v1.0
##########################################

#----------------------------------------
#mysql data
HOST="localhost"
USER="root"
PORT="3306"
PASSWD="12345"
DB_NAME="shadowsocks"
SQL_FILES="invite_code.sql ss_admin.sql ss_node.sql ss_reset_pwd.sql user.sql"
CREATED=0
#----------------------------------------

#check OS version
CHECK_OS_VERSION=`cat /etc/issue |sed -n "$1"p|awk '{printf $1}' |tr 'a-z' 'A-Z'`

#list the software need to be installed to the variable FILELIST
TOOLS_LIBS="python-pip mysql-server libapache2-mod-php5 python-m2crypto php5-cli git apache2 php5-gd php5-mysql php5-dev libmysqlclient15-dev php5-curl php-pear language-pack-zh*"


## update system
function update_ubuntu(){
	echo "apt-get update"
	apt-get update
}

## check whether system is Ubuntu or not
function check_OS_distributor(){
echo "checking distributor and release ID ..."
if [[ "${CHECK_OS_VERSION}" == "UBUNTU" ]] ;then
	echo -e "\tCurrent OS: ${CHECK_OS_VERSION}"
	UBUNTU=1
else
	echo -e "\tCurrent OS is not ${CHECK_OS_VERSION}!!!"
	exit 1
fi
}

#install one software every cycle
function install_soft_for_each(){
	echo "check OS version..."
	check_OS_distributor
	if [ ${UBUNTU} -eq 0 ];then
		echo "there are some errors I meet on CentOs, please try Ubuntu."
		echo "If you setup success please contact and help me to solve that, many thanks!!"
	else
	echo "Will install below software on your Ubuntu system:"
	update_ubuntu
	for file in ${TOOLS_LIBS}
	do
		trap 'echo -e "\ninterrupted by user, exit";exit' INT
		echo "========================="
		echo "installing $file ..."
		echo "-------------------------"
		apt-get install $file -y
		sleep 1
		echo "$file installed ."
	done
	pip install cymysql shadowsocks
	fi
}

#mysql operation
function mysql_op()
{
	if [ ${CREATED} -eq 0 ];then
		mysql -h${HOST} -P${PORT} -u${USER} -p${PASSWD} -e "$1"
	else
		mysql -h${HOST} -P${PORT} -u${USER} -p${PASSWD} ${DB_NAME} -e "$1"
	fi
}

#setup manyuser ss
function setup_manyuser_ss()
{
	SS_ROOT=/root/shadowsocks/shadowsocks
	echo -e "download manyuser shadowsocks\n"
	cd /root
	git clone -b manyuser https://github.com/mengskysama/shadowsocks.git
	cd ${SS_ROOT}
	#modify Config.py
	echo -e "modify Config.py...\n"
	sed -i "/^MYSQL_HOST/ s#'.*'#'localhost'#" ${SS_ROOT}/Config.py
	sed -i "/^MYSQL_USER/ s#'.*'#'${USER}'#" ${SS_ROOT}/Config.py
	sed -i "/^MYSQL_PASS/ s#'.*'#'${PASSWD}'#" ${SS_ROOT}/Config.py
	sed -i "/rc4-md5/ s#"rc4-md5"#aes-256-cfb#" ${SS_ROOT}/config.json
	#create database shadowsocks
	echo -e "create database shadowsocks...\n"
	create_db_sql="create database IF NOT EXISTS ${DB_NAME}"
	mysql_op "${create_db_sql}"
	if [ $? -eq 0 ];then
		 CREATED=1
	fi
	#import shadowsocks sql
	echo -e "import shadowsocks sql..."
	import_db_sql="source ${SS_ROOT}/shadowsocks.sql"
	mysql_op "${import_db_sql}"
}

#setup ss-panel 
function setup_sspanel()
{
	PANEL_ROOT=/root/ss-panel
	echo -e "download ss-panel ...\n"
	cd /root
	git clone https://github.com/orvice/ss-panel.git
	#import pannel sql
	for mysql in ${SQL_FILES}
	do
		import_panel_sql="source ${PANEL_ROOT}/sql/${mysql}"
		mysql_op "${import_panel_sql}"
	done
	#modify config
	echo -e "modify lib/config-simple.php...\n"
	if [ -f "${PANEL_ROOT}/lib/config-simple.php" ];then
		mv ${PANEL_ROOT}/lib/config-simple.php ${PANEL_ROOT}/lib/config.php
	fi
	sed -i "/DB_PWD/ s#'password'#'${PASSWD}'#" ${PANEL_ROOT}/lib/config.php
	sed -i "/DB_DBNAME/ s#'db'#'${DB_NAME}'#" ${PANEL_ROOT}/lib/config.php
	cp -rd ${PANEL_ROOT}/* /var/www/html/
	rm -rf /var/www/html/index.html
}

#start shadowsocks server
function start_ss()
{
	if [ $UBUNTU -eq 1 ];then
		service apache2 restart
	else
		echo "Apache2 restart failed!!!"
		echo "ERROR!!!"
		exit 1
	fi
	nohup python /root/shadowsocks/shadowsocks/server.py > /var/log/shadowsocks.log 2>&1 &
	echo -e "congratulations, shadowsocks server starting...\n"
	echo -e "The log file is in /var/log/shadowsocks.log..."
	echo -e "visit your ip you can see the web, you can configure it at /var/www/html"
}

#====================
# main
#
#judge whether root or not
if [ "$UID" -eq 0 ];then
	install_soft_for_each
	setup_manyuser_ss
	setup_sspanel
	start_ss
else
	echo -e "please run it as root user again !!!\n"
	exit 1
fi
