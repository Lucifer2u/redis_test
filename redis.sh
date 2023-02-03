#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8
redis_version=6.2.6
release=`cat /etc/*release /etc/*version 2>/dev/null | grep -Eo '([0-9]{1,2}\.){1,3}' | cut -d '.' -f1 | head -1`;

if [ $(whoami) != "root" ];then
	echo "璇蜂娇鐢╮oot鏉冮檺鎵цRedis瀹夎鍛戒护锛�"
	exit 1;
fi

whereis -b yum | grep '/yum' >/dev/null && SysName='CentOS';
[ "$SysName" == ''  ] && echo '褰撳墠鎿嶄綔绯荤粺涓嶆敮鎸佽瀹夎鑴氭湰' && exit;

function Install()
{

if [ -f /usr/local/bin/redis-server ];then
	echo -e "\033[32mRedis宸插畨瑁呰繃锛岃鍕块噸澶嶅畨瑁咃紒\033[0m"
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
	echo -e "鈥斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€�
Redis ${redis_version} 瀹夎澶辫触锛�
鈥斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€�";
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
echo -e "\033[32mRedis ${redis_version} 瀹夎鎴愬姛锛乗033[0m"
echo -e "=================================================================="
echo  "杩炴帴鍦板潃: 127.0.0.1:6379"
echo  "杩炴帴鍛戒护: redis-cli -h 127.0.0.1 -p 6379"
echo  "閰嶇疆鏂囦欢: /etc/redis/redis.conf"
echo -e "=================================================================="

}

function Upgrade()
{

if [ ! -f /usr/local/bin/redis-server ];then
	echo -e "\033[32mRedis鏈畨瑁咃紝璇峰厛鎵ц瀹夎鍛戒护锛乗033[0m"
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
echo -e "\033[32mRedis ${redis_version} 鍗囩骇鎴愬姛锛乗033[0m"
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
echo -e "\033[32mRedis ${redis_version} 鍗歌浇鎴愬姛锛乗033[0m"
echo -e "=================================================================="

}

function Init(){
clear
echo -e "==================================================================
	\033[32mRedis ${redis_version} 瀹夎鑿滃崟\033[0m
	璇疯緭鍏ヤ互涓嬫暟瀛楃户缁搷浣�
==================================================================
1. 鈼� 瀹夎 Redis ${redis_version}
2. 鈼� 鍗囩骇 Redis ${redis_version}
3. 鈼� 鍗歌浇 Redis
0. 鈼� 閫€鍑哄畨瑁�"
read -p "璇疯緭鍏ュ簭鍙峰苟鍥炶溅锛�" num
case "$num" in
[1] ) (Install);;
[2] ) (Upgrade);;
[3] ) (Uninstall);;
[0] ) (exit);;
*) (Init);;
esac
}

Init