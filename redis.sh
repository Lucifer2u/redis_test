#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8
redis_version=6.2.6
release=`cat /etc/*release /etc/*version 2>/dev/null | grep -Eo '([0-9]{1,2}\.){1,3}' | cut -d '.' -f1 | head -1`;

if [ $(whoami) != "root" ];then
	echo "请使用root权限执行Redis安装命令！"
	exit 1;
fi

whereis -b yum | grep '/yum' >/dev/null && SysName='CentOS';
[ "$SysName" == ''  ] && echo '当前操作系统不支持该安装脚本' && exit;

function Install()
{

if [ -f /usr/local/bin/redis-server ];then
	echo -e "\033[32mRedis已安装过，请勿重复安装！\033[0m"
	exit 1;
fi

yum -y install gcc automake autoconf libtool make

groupadd redis
useradd -g redis -s /sbin/nologin redis

VM_OVERCOMMIT_MEMORY=$(cat /etc/sysctl.conf|grep vm.overcommit_memory)
NET_CORE_SOMAXCONN=$(cat /etc/sysctl.conf|grep net.core.somaxconn)
if [ -z "${VM_OVERCOMMIT_MEMORY}" ] && [ -z "${NET_CORE_SOMAXCONN}" ];then
	echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
	echo "net.core.somaxconn = 1024" >> /etc/sysctl.conf
	sysctl -p
fi

wget -O redis-$redis_version.tar.gz http://download.redis.io/releases/redis-$redis_version.tar.gz
tar zxvf redis-$redis_version.tar.gz
cd redis-$redis_version
make && make install
if test $? != 0; then
	echo -e "————————————————————————————————————————————————————
Redis ${redis_version} 安装失败！
————————————————————————————————————————————————————";
exit 1
fi

if [ ! -d /home/redis ];then
	mkdir -p /home/redis
	chown redis:redis /home/redis
fi

if [ ! -d /var/log/redis ];then
	mkdir -p /var/log/redis
	chown redis:redis /var/log/redis
fi

if [ ! -f /etc/redis/redis.conf ];then
	mkdir -p /etc/redis
	\cp ./redis.conf /etc/redis/redis.conf
	sed -i 's/daemonize no/daemonize yes/' /etc/redis/redis.conf
	sed -i 's/# supervised auto/supervised auto/' /etc/redis/redis.conf
	sed -i 's/logfile ""/logfile "\/var\/log\/redis\/redis.log"/' /etc/redis/redis.conf
	sed -i 's/dir .\//dir \/home\/redis\//' /etc/redis/redis.conf
	chown redis:redis /etc/redis -R
fi

if [ "$release" == "6" ];then
	wget -O /etc/init.d/redis http://f.cccyun.cc/redis/redis.init
	chmod +x /etc/init.d/redis

	chkconfig --add redis
	chkconfig redis on
	service redis start
else
	wget -O /usr/lib/systemd/system/redis.service http://f.cccyun.cc/redis/redis.service

	systemctl daemon-reload
	systemctl enable redis
	systemctl start redis
fi

cd ..
rm -rf redis-$redis_version redis-$redis_version.tar.gz

echo -e "=================================================================="
echo -e "\033[32mRedis ${redis_version} 安装成功！\033[0m"
echo -e "=================================================================="
echo  "连接地址: 127.0.0.1:6379"
echo  "连接命令: redis-cli -h 127.0.0.1 -p 6379"
echo  "配置文件: /etc/redis/redis.conf"
echo -e "=================================================================="

}

function Upgrade()
{

if [ ! -f /usr/local/bin/redis-server ];then
	echo -e "\033[32mRedis未安装，请先执行安装命令！\033[0m"
	exit 1;
fi

wget -O redis-$redis_version.tar.gz http://download.redis.io/releases/redis-$redis_version.tar.gz
tar zxvf redis-$redis_version.tar.gz
cd redis-$redis_version
make
make install
systemctl restart redis

cd ..
rm -rf redis-$redis_version redis-$redis_version.tar.gz

echo -e "=================================================================="
echo -e "\033[32mRedis ${redis_version} 升级成功！\033[0m"
echo -e "=================================================================="

}

function Uninstall()
{

if [ "$release" == "6" ];then
	service redis stop
	chkconfig redis off
	chkconfig --del redis
	rm -f /etc/init.d/redis
else
	systemctl stop redis
	systemctl disable redis
	rm -f /usr/lib/systemd/system/redis.service
fi

rm -f /usr/local/bin/redis-*
rm -rf /home/redis
rm -rf /etc/redis

echo -e "=================================================================="
echo -e "\033[32mRedis ${redis_version} 卸载成功！\033[0m"
echo -e "=================================================================="

}

function Init(){
clear
echo -e "==================================================================
	\033[32mRedis ${redis_version} 安装菜单\033[0m
	请输入以下数字继续操作
==================================================================
1. ◎ 安装 Redis ${redis_version}
2. ◎ 升级 Redis ${redis_version}
3. ◎ 卸载 Redis
0. ◎ 退出安装"
read -p "请输入序号并回车：" num
case "$num" in
[1] ) (Install);;
[2] ) (Upgrade);;
[3] ) (Uninstall);;
[0] ) (exit);;
*) (Init);;
esac
}

Install