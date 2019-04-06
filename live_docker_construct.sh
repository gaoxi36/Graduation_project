#!/bin/bash 
# 前提条件
# 1./export/dockershare/live/ 下放置本文件
# 2./export/dockershare/live/deploy/ 下配置所有的云豹（relay、edge、ingest、l2）、金猫、黑猫、配置下发、锈猫
# 3.安装雪豹需要配置go环境  /export/dockershare/ 下有go的tar包go1.10.1.linux-amd64.tar.gz 当然，docker需要安装 gcc
# 4.雪豹mysql数据库需要执行sql /export/dockershar/live/snow-leopard.sql 脚本
# 5.rpm包包括nginx的版本
# 与docker共享的文件夹  后续可以通过共享文件夹来通过docker宿主机器更新版本
readonly SHARE_DIR="/export/dockershare/"
readonly DOCKER_HOST_SHARE_DIR="/export/dockershare/"

if [ $# -lt 2 ] ; then 
	echo "USAGE: $0 LIVE_ROLE SYSTEM_ALIAS" 
	echo " e.g.: $0 snow CACTUS" 
	exit 1; 
fi

# 各个docker的统一后缀 不允许出现连接符 -
DOCKER_NAME_SUFFIX=$2

COMPILER="live.compiler.${DOCKER_NAME_SUFFIX}"
SNOW_LEOPARD="live-snowleopard.${DOCKER_NAME_SUFFIX}"
SNOW_LEOPARD_REDIS="live-snow-redis.${DOCKER_NAME_SUFFIX}"
SNOW_LEOPARD_MYSQL="live-snow-mysql.${DOCKER_NAME_SUFFIX}"
TRANSCODE="live-transcode.${DOCKER_NAME_SUFFIX}"
SNOW_DOCKER_HOST=33000
SNOW_MYSQL_PORT=33100
SNOW_REDIS_PORT=33200
SRS_DOCKER_RELAY_START=35000
SRS_DOCKER_EDGE_START=37000
SRS_CAST_PORT_HTTP=80
SRS_CAST_PORT_HTTPS=443
SRS_CAST_PORT_RTMP=1935
TRANSCODE_DOCKER_PORT=33400

# docker镜像名
#readonly DOCKER_BASE_URL="registry.pidcdn.jcloud.com/cdn-qin"
#readonly DOCKER_BASE_URL="cdn-qin"
readonly BASE_DOCKER="centos:6.6"

# docker 网段名称
readonly DOCKER_BRIDAGE="bridge"

# rpm 包名
readonly JDWS="jdws-cloud-1.10.3-6.el6.x86_64.rpm"
readonly JDWS_LUAJIT="LuaJIT-2.0.3-CentOS6.el6.x86_64.rpm"

# 各种ip相关
IP_SNOW_SERVER="169.254.12.6"
IP_RELAY_VIP="169.254.12.12"

# 各个模块的测试domain
readonly DOMAIN_SNOW_REDIS="live-redis-hb3.jcloud.com"
readonly DOMAIN_SNOW_MYSQL="test.database.env-jcloud-cdn.com"
readonly DOMAIN_SNOW_LIVECONFIG="live.jcloud.com"
readonly DOMAIN_SNOW_SRS="live-inner.jcloud.com"
readonly DOMAIN_RELAY_HD="hb-origin.jdcloud.com"
readonly DOMAIN_RELAY_VIP="origin.jcloud.com"
readonly DOMAIN_TRANSCODE="live-transpond-online.jdcloud.com"
readonly DOMAIN_INTERNAL_MIX="test-internal-mix.push.jcloud.com"
readonly DOMAIN_SNOW_CENTER="live-center.jdcloud.com"


#中转服务器的命名规则  地域-昵称-RELAY-编号
#边缘服务器的命名规则  地域-运营商-昵称-EDGE-编号  在一个地区的边缘需要写到一块，dc_host生成的时候需要
level_2=("YF-$DOCKER_NAME_SUFFIX-RELAY-1" "YF-$DOCKER_NAME_SUFFIX-RELAY-2" "JN-$DOCKER_NAME_SUFFIX-RELAY-1" "JN-$DOCKER_NAME_SUFFIX-RELAY-2")
#level_2=("YF-$DOCKER_NAME_SUFFIX-RELAY-1")
level_1=("GZ-CM-$DOCKER_NAME_SUFFIX-RTMP-10" "GZ-CM-$DOCKER_NAME_SUFFIX-RTMP-11" 
			"GZ-CT-$DOCKER_NAME_SUFFIX-RTMP-20" "GZ-CT-$DOCKER_NAME_SUFFIX-RTMP-21"
			"TJ-UNI-$DOCKER_NAME_SUFFIX-RTMP-30" "TJ-UNI-$DOCKER_NAME_SUFFIX-RTMP-31"
			"TJ-CT-$DOCKER_NAME_SUFFIX-RTMP-40" "TJ-CT-$DOCKER_NAME_SUFFIX-RTMP-41" 
			"JN-UNI-$DOCKER_NAME_SUFFIX-RTMP-50" "JN-UNI-$DOCKER_NAME_SUFFIX-RTMP-51"
			"BJ-GWBN-$DOCKER_NAME_SUFFIX-RTMP-60" "BJ-GWBN-$DOCKER_NAME_SUFFIX-RTMP-61")
#level_1=("GZ-CM-$DOCKER_NAME_SUFFIX-RTMP-10")


function getunbindport_relay {
	local LOCAL_1=$1
	#echo $LOCAL_1
	lsof -i:$LOCAL_1 >> /dev/null
	if [ $? -eq 1 ];
	then
		lsof -i:`expr $LOCAL_1 + 1` >> /dev/null
		if [ $? -eq 1 ];
		then
			lsof -i:`expr $LOCAL_1 + 2` >> /dev/null
			if [ $? -eq 1 ];
			then
				SRS_DOCKER_RELAY_START=$LOCAL_1
			else
				getunbindport_relay `expr $LOCAL_1 + 100`
			fi  
		else
			getunbindport_relay `expr $LOCAL_1 + 100`
		fi  
	else
		getunbindport_relay `expr $LOCAL_1 + 100`
	fi  
}

function getunbindport_edge {
	local LOCAL_1=$1
	#echo $LOCAL_1
	lsof -i:$LOCAL_1 >> /dev/null
	if [ $? -eq 1 ];
	then
		lsof -i:`expr $LOCAL_1 + 1` >> /dev/null
		if [ $? -eq 1 ];
		then
			lsof -i:`expr $LOCAL_1 + 2` >> /dev/null
			if [ $? -eq 1 ];
			then
				SRS_DOCKER_EDGE_START=$LOCAL_1
			else
				getunbindport_edge `expr $LOCAL_1 + 100`
			fi  
		else
			getunbindport_edge `expr $LOCAL_1 + 100`
		fi  
	else
		getunbindport_edge `expr $LOCAL_1 + 100`
	fi  
}

function getunbindport_snow {
	local LOCAL_1=$1
	#echo $LOCAL_1
	lsof -i:$LOCAL_1 >> /dev/null
	if [ $? -eq 1 ];
	then
		SNOW_DOCKER_HOST=$LOCAL_1
		echo $LOCAL_1
	else
		getunbindport_snow `expr $LOCAL_1 + 10`
	fi  
}

function getunbindport_transcode {
	local LOCAL_1=$1
	#echo $LOCAL_1
	lsof -i:$LOCAL_1 >> /dev/null
	if [ $? -eq 1 ];
	then
		TRANSCODE_DOCKER_PORT=$LOCAL_1
		echo $LOCAL_1
	else
		getunbindport_transcode `expr $LOCAL_1 + 10`
	fi
}

function getunbindport_mysql {
	local LOCAL_1=$1
	lsof -i:$LOCAL_1 >> /dev/null
	if [ $? -eq 1 ];
	then
		SNOW_MYSQL_PORT=$LOCAL_1
	else
		getunbindport_mysql `expr $LOCAL_1 + 1`
	fi  
}

function getunbindport_redis {
	local LOCAL_1=$1
	lsof -i:$LOCAL_1 >> /dev/null
	if [ $? -eq 1 ];
	then
		SNOW_REDIS_PORT=$LOCAL_1
	else
		getunbindport_redis `expr $LOCAL_1 + 1`
	fi  
}
			
function create_relay {
	container=(${level_2[@]})

	snow_hi=$(echo $SNOW_LEOPARD | tr '[a-z]' '[A-Z]')
    IP_SNOW_SERVER=`docker inspect --format="{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" $snow_hi |awk '{print $3}'`

	echo "snow leopard ip = $IP_SNOW_SERVER"
	for mechine in ${container[@]}
	do
		mechine_lo=$(echo $mechine | tr '[A-Z]' '[a-z]')
		mechine_hi=$(echo $mechine | tr '[a-z]' '[A-Z]')
		#create_container $mechine_hi $mechine_lo centos:6.6 127.0.0.1
		#relay need cast port to host
		getunbindport_relay $SRS_DOCKER_RELAY_START
		local LOCAL_PORT1=`expr $SRS_DOCKER_RELAY_START + 1`
		local LOCAL_PORT2=`expr $SRS_DOCKER_RELAY_START + 2`
		docker run --name "${mechine_hi}" \
            -tid --cap-add=SYS_TIME --cap-add ALL --net "${DOCKER_BRIDAGE}" --hostname="${mechine_lo}" \
            -v "${SHARE_DIR}:${DOCKER_HOST_SHARE_DIR}" -p "$SRS_DOCKER_RELAY_START:$SRS_CAST_PORT_RTMP" \
			-p "$LOCAL_PORT1:$SRS_CAST_PORT_HTTP" -p "$LOCAL_PORT2:$SRS_CAST_PORT_HTTPS" \
			$BASE_DOCKER /bin/bash
		mechine_ip=`get_ip $mechine_hi`
		sub_mechine=`echo $mechine_lo | cut -d '-' -f 1,2,3`
		#通过雪豹api接口添加
		
		curl -X POST "http://$IP_SNOW_SERVER/Api/Host/Add?site_id=10000&timestamp=1504258467&signature=cdn-live-test-key&host_name=$mechine_lo&cm_ip=$mechine_ip&ct_ip=$mechine_ip&uni_ip=$mechine_ip&default_ip=$mechine_ip&inner_ip=$mechine_ip&node_level=3&edge_node=$sub_mechine"
		
		docker exec "$mechine_hi" /bin/bash -c \
			"sed -i 's#ZONE=\"UTC\"#ZONE=\"Asia/Shanghai\"#' /etc/sysconfig/clock && \
			sed -i 's#True#false#' /etc/sysconfig/clock && echo 'ARC=false' >> /etc/sysconfig/clock && \
			ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
			yum -y install tar gcc lsof vixie-cron php-cli && rpm -hiv /export/dockershare/live/rpm/$JDWS_LUAJIT && \
			rpm -hiv /export/dockershare/live/rpm/$JDWS && cp -r /export/servers/nginx/update/sbin /export/servers/nginx/sbin && \
			tar -xzf `ls -lt /export/dockershare/live/deploy/live-golden-cat/*.tar.gz | awk '{print $9}' | head -1 ` -C /export/servers/nginx/ && \
			mkdir -p /export/servers/live-config-manager /export/hls/proxy_cache /export/cache/proxy_cache /export/servers/live-black-cat && \
			tar -xzf `ls -lt /export/dockershare/live/deploy/live-config-manager/*.tar.gz | awk '{print $9}' | head -1 ` -C /export/servers/live-config-manager/ && echo '${IP_SNOW_SERVER} ${DOMAIN_SNOW_LIVECONFIG}' >> /etc/hosts && \
			tar -xzf `ls -lt /export/dockershare/live/deploy/live-black-cat/*.tar.gz | awk '{print $9}' | head -1 ` -C /export/servers/live-black-cat/ && \
			sed -i 's/7#$%uy6u9/test10000/g' /export/servers/live-black-cat/conf/live-black-cat.conf && \
			/export/servers/live-black-cat/bin/control start && \
			echo '${IP_SNOW_SERVER} ${DOMAIN_SNOW_SRS}' >> /etc/hosts && \
			echo '${IP_SNOW_SERVER} ${DOMAIN_SNOW_CENTER}' >> /etc/hosts && \
			sed -i 's/172.30.31.3/${IP_SNOW_SERVER}/g' /export/servers/nginx/plugins/lua/jccdn/dynamic_hls/entry.lua && \
			sed -i 's/172.30.31.3/${IP_SNOW_SERVER}/g' /export/servers/nginx/plugins/lua/jccdn/base_accesskey/entry.lua && \
			cp /export/dockershare/live/deploy/mime.types /export/servers/nginx/conf/mime.types && \
			cp /export/dockershare/live/deploy/nginx.conf /export/servers/nginx/conf/nginx.conf && \
			mkdir -p /export/hls"
		#nginx需要在crond 任务后手动启动 install.sh 需要在compiler机器中编译过不同类型的srs
		docker exec "$mechine_hi" /bin/bash -c \
			"service crond start && sh /export/dockershare/live/deploy/refresh_crond.sh relay && \
			cd /export/dockershare/live/deploy && \
			sh ./live-cloud-leopard-relay/output/install.sh && \
			sh ./live-cloud-leopard-hls/output/install.sh && \
			sh ./live-cloud-leopard-ingest/output/install.sh && \
			cd /export/servers/live-config-manager; php /export/servers/live-config-manager/nginx_vhost_conf_update.php relay 1 && \
			service nginx start"
		#最后注意，需要添加一个回源站的服务，源站（live-transpond-online.jdcloud.com）会转推 给中转
	done
}

function remove_relay {
	container=(${level_2[@]})

	for mechine in ${container[@]}
	do
		mechine_hi=$(echo $mechine | tr '[a-z]' '[A-Z]')
		mechine_lo=$(echo $mechine | tr '[A-Z]' '[a-z]')
		docker rm -f $mechine_hi
		snow_hi=$(echo $SNOW_LEOPARD | tr '[a-z]' '[A-Z]')
		IP_SNOW_SERVER=`docker inspect --format="{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" $snow_hi |awk '{print $3}'`
		curl -X POST "http://$IP_SNOW_SERVER/Api/Host/Del?site_id=10000&timestamp=1504258467&signature=cdn-live-test-key&host_name=$mechine_lo"
	done
}

function create_container {
    local docker_name=$1
    local hostname=$2
    local imagename=$3
	local ip=$4

    docker run --name "${docker_name}" \
            -tid --cap-add ALL --cap-add=SYS_TIME --net "${DOCKER_BRIDAGE}" --hostname="${hostname}" \
            -v "${SHARE_DIR}:${DOCKER_HOST_SHARE_DIR}" ${imagename} /bin/bash
}

function help {
    echo "${0} <relay|edge|ingest|l2_ingest|hls|snow_leopard|pull|help> <alias>"
}

function get_ip {
    docker inspect $1 | grep "IPAddress"  | grep -v Secondary | grep -v "\"\""| head -n 1 | awk -F ":" '{print $2}' | awk -F '"' '{print $2}'
}

function create_snow {
	#新建redis mysql后，获取ip,写入snow leopard中的/etc/hosts中
	redis_lo=$(echo $SNOW_LEOPARD_REDIS | tr '[A-Z]' '[a-z]')
	redis_hi=$(echo $SNOW_LEOPARD_REDIS | tr '[a-z]' '[A-Z]')
	#create_container $redis_hi $redis_lo redis:latest 127.0.0.1
	getunbindport_redis $SNOW_REDIS_PORT
	docker run --name "${redis_hi}" -p "$SNOW_REDIS_PORT:6379" \
		-tid --cap-add ALL --cap-add=SYS_TIME --net "${DOCKER_BRIDAGE}" --hostname="${redis_lo}" \
		-v "${SHARE_DIR}:${DOCKER_HOST_SHARE_DIR}" redis:latest

	redis_ip=`get_ip $redis_hi`
	echo "$redis_ip"

	#mysq 版本为5.7
	mysql_lo=$(echo $SNOW_LEOPARD_MYSQL | tr '[A-Z]' '[a-z]')
	mysql_hi=$(echo $SNOW_LEOPARD_MYSQL | tr '[a-z]' '[A-Z]')
	getunbindport_mysql $SNOW_MYSQL_PORT
    docker run --name "${mysql_hi}" -v "${SHARE_DIR}:${DOCKER_HOST_SHARE_DIR}"\
            -tid --cap-add ALL --cap-add=SYS_TIME --hostname="${mysql_lo}" -p "$SNOW_MYSQL_PORT:3306" \
            -e MYSQL_ROOT_PASSWORD=root -e MYSQL_USER=admin -e MYSQL_PASSWORD=admin mysql:5.7
	mysql_ip=`get_ip $mysql_hi`
	echo $mysql_ip
	sleep 10

	docker exec "${mysql_hi}" /bin/bash -c \
			"mysql -uroot -proot < ${DOCKER_HOST_SHARE_DIR}live/snow-leopard.sql"
	
	#snow leopard need outside port to guys call the api
	snow_lo=$(echo $SNOW_LEOPARD | tr '[A-Z]' '[a-z]')
	snow_hi=$(echo $SNOW_LEOPARD | tr '[a-z]' '[A-Z]')
	getunbindport_snow $SNOW_DOCKER_HOST
	SNOW_DOCKER_HOST_HTTPS=`expr $SNOW_DOCKER_HOST + 1`
    docker run --name "$snow_hi" -p "$SNOW_DOCKER_HOST:80" -p "$SNOW_DOCKER_HOST_HTTPS:443"\
            -tid --cap-add ALL --cap-add=SYS_TIME --hostname="${snow_lo}" \
            -v "$SHARE_DIR:$DOCKER_HOST_SHARE_DIR" $BASE_DOCKER /bin/bash
#	#需要提前编译snow-leopard包
	docker exec "${snow_hi}" /bin/bash -c \
		"sed -i 's#ZONE=\"UTC\"#ZONE=\"Asia/Shanghai\"#' /etc/sysconfig/clock && \
		sed -i 's#True#false#' /etc/sysconfig/clock && echo 'ARC=false' >> /etc/sysconfig/clock && \
		ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
		mkdir -p /export/servers/live-snow-leopard /export/Packages/live-snow-leopard/log && \
        echo '${redis_ip} ${DOMAIN_SNOW_REDIS}' >> /etc/hosts && \
        echo '${mysql_ip} ${DOMAIN_SNOW_MYSQL}' >> /etc/hosts && \
		yum -y install tar lsof gcc epel-release && \
		yum -y install nginx && \
		tar -C /usr/local -xzf ${DOCKER_HOST_SHARE_DIR}go1.10.1.linux-amd64.tar.gz && \
		mkdir -p /home/gopath /export/Logs && \
		echo 'export GOROOT=/usr/local/go' >> /root/.bashrc && \
		echo 'export GOBIN=\$GOROOT/bin' >> /root/.bashrc && \
		echo 'export GOPATH=/home/gopath' >> /root/.bashrc && \
		echo 'export PATH=\$PATH:\$GOBIN:\$GOPATH/bin' >> /root/.bashrc && \
		source /root/.bashrc && cd /etc/nginx && \
		openssl req -newkey rsa:2048 -nodes -keyout cert.key -x509 -days 365 -out cert.pem -subj '/C=CN/ST=BJ/L=beijing/O=JD/OU=cloud/CN=jd.com/emailAddress=pid@jd.com' && \
		mv ./conf.d/default.conf ./conf.d/default.bac && \
		cp /export/dockershare/live/deploy/nginx_conf/snow_default.conf /etc/nginx/conf.d/default.conf && \
		mv ./conf.d/ssl.conf ./conf.d/ssl.bac && \
		cp /export/dockershare/live/deploy/nginx_conf/snow_ssl.conf /etc/nginx/conf.d/ssl.conf && \
		cp /export/dockershare/live/deploy/nginx_conf/snow_upstream.conf /etc/nginx/conf.d/upstream.conf && \
		service nginx start && \
		tar -C /export/servers/live-snow-leopard -xzf `ls -lt /export/dockershare/live/deploy/live-snow-leopard/snow-leopard/snow-leopard*.tar.gz | awk '{print $9}' | head -1` && \
		mv /export/servers/live-snow-leopard/conf/app.conf /export/servers/live-snow-leopard/conf/app.conf.old && \
		cp /export/dockershare/live/deploy/app.conf /export/servers/live-snow-leopard/conf/app.conf && \
		/export/servers/live-snow-leopard/bin/control start"
	sleep 3
#	#日志清理
	docker exec "${snow_hi}" /bin/bash -c \
		"yum -y install vixie-cron && \
		service crond start && sh /export/dockershare/live/deploy/refresh_crond.sh snow"
	snow_ip=`get_ip $snow_hi`
	IP_SNOW_SERVER=$snow_ip
	#添加site，没有site时relay和edge的nginx会启动失败
	sh /export/dockershare/live/deploy/add_site.sh $snow_hi
}

function random()
{
    min=$1;
    max=$2-$1;
    num=$(date +%s+%N);
    ((retnum=num%max+min));
    #进行求余数运算即可
    echo $retnum;
    #这里通过echo 打印出来值，然后获得函数的，stdout就可以获得值
    #还有一种返回，定义全价变量，然后函数改下内容，外面读取
}

#dege需要在host里面配置中转服务器hb-origin.jdcloud.com
function create_edge {
	container=(${level_1[@]})

	snow_hi=$(echo $SNOW_LEOPARD | tr '[a-z]' '[A-Z]')
	relay_vip=$(echo ${level_2[0]} | tr '[a-z]' '[A-Z]')
    IP_SNOW_SERVER=`docker inspect --format="{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" $snow_hi |awk '{print $3}'`
	echo "snow leopard ip = $IP_SNOW_SERVER"
	IP_RELAY_VIP=`docker inspect --format="{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" $relay_vip |awk '{print $3}'`
	echo "relay vip = $IP_RELAY_VIP"
	
	for mechine in ${container[@]}
	do
		mechine_lo=$(echo $mechine | tr '[A-Z]' '[a-z]')
		mechine_hi=$(echo $mechine | tr '[a-z]' '[A-Z]')
		#edge need cast port to host
		getunbindport_edge $SRS_DOCKER_EDGE_START
		local LOCAL_PORT1=`expr $SRS_DOCKER_EDGE_START + 1`
		local LOCAL_PORT2=`expr $SRS_DOCKER_EDGE_START + 2`
		docker run --name "${mechine_hi}" \
            -tid --cap-add ALL --cap-add=SYS_TIME --net "${DOCKER_BRIDAGE}" --hostname="${mechine_lo}" \
            -v "${SHARE_DIR}:${DOCKER_HOST_SHARE_DIR}" -p "$SRS_DOCKER_EDGE_START:$SRS_CAST_PORT_RTMP" \
			-p "$LOCAL_PORT1:$SRS_CAST_PORT_HTTP" -p "$LOCAL_PORT2:$SRS_CAST_PORT_HTTPS" \
			$BASE_DOCKER /bin/bash
		mechine_ip=`get_ip $mechine_hi`
		#sub_mechine is need by snow leopard host add with edge node
		sub_mechine=`echo $mechine_lo | cut -d '-' -f 1,2,3`
		#通过雪豹api接口添加
		curl -X POST "http://$IP_SNOW_SERVER/Api/Host/Add?site_id=10000&timestamp=1504258467&signature=cdn-live-test-key&host_name=$mechine_lo&cm_ip=$mechine_ip&ct_ip=$mechine_ip&uni_ip=$mechine_ip&default_ip=$mechine_ip&inner_ip=$mechine_ip&node_level=1&edge_node=$sub_mechine"
		
		docker exec "$mechine_hi" /bin/bash -c \
			"sed -i 's#ZONE=\"UTC\"#ZONE=\"Asia/Shanghai\"#' /etc/sysconfig/clock && \
			sed -i 's#True#false#' /etc/sysconfig/clock && echo 'ARC=false' >> /etc/sysconfig/clock && \
			ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
			yum -y install tar gcc lsof vixie-cron php-cli && rpm -hiv /export/dockershare/live/rpm/$JDWS_LUAJIT && \
			rpm -hiv /export/dockershare/live/rpm/$JDWS && cp -r /export/servers/nginx/update/sbin /export/servers/nginx/sbin && \
			tar -xzf `ls -lt /export/dockershare/live/deploy/live-golden-cat/*.tar.gz | awk '{print $9}' | head -1 ` -C /export/servers/nginx/ && \
			mkdir -p /export/servers/live-config-manager /export/hls/proxy_cache /export/servers/live-black-cat && \
			tar -xzf `ls -lt /export/dockershare/live/deploy/live-config-manager/*.tar.gz | awk '{print $9}' | head -1 ` -C /export/servers/live-config-manager/ && echo '${IP_SNOW_SERVER} ${DOMAIN_SNOW_LIVECONFIG}' >> /etc/hosts && \
			tar -xzf `ls -lt /export/dockershare/live/deploy/live-black-cat/*.tar.gz | awk '{print $9}' | head -1 ` -C /export/servers/live-black-cat/ && \
			/export/servers/live-black-cat/bin/control start && \
			echo '${IP_SNOW_SERVER} ${DOMAIN_SNOW_SRS}' >> /etc/hosts && \
			echo '${IP_RELAY_VIP} ${DOMAIN_RELAY_HD}' >> /etc/hosts && \
			echo '${IP_RELAY_VIP} ${DOMAIN_RELAY_VIP}' >> /etc/hosts && \
			echo '${IP_SNOW_SERVER} ${DOMAIN_SNOW_CENTER}' >> /etc/hosts && \
			sed -i 's/172.30.31.3/${IP_SNOW_SERVER}/g' /export/servers/nginx/plugins/lua/jccdn/dynamic_hls/entry.lua && \
			sed -i 's/172.30.31.3/${IP_SNOW_SERVER}/g' /export/servers/nginx/plugins/lua/jccdn/base_accesskey/entry.lua && \
			cp /export/dockershare/live/deploy/mime.types /export/servers/nginx/conf/mime.types && \
			cp /export/dockershare/live/deploy/nginx.conf /export/servers/nginx/conf/nginx.conf"
		#srs需要手动部署  crond 任务需要手动添加 nginx需要在crond 任务后手动启动
		#edge 需要配置origin.jcloud.com 域名
		docker exec "$mechine_hi" /bin/bash -c \
			"service crond start && sh /export/dockershare/live/deploy/refresh_crond.sh edge && \
			cd /export/dockershare/live/deploy && \
			sh ./live-cloud-leopard-edge/output/install.sh && \
			sh ./live-cloud-leopard-l2/output/install.sh && \
			cd /export/servers/live-config-manager; php /export/servers/live-config-manager/nginx_vhost_conf_update.php edge 1 && \
			service nginx start"
	done

	`sh $0 dc_host $DOCKER_NAME_SUFFIX`
}

function remove_edge {
	container=(${level_1[@]})
	for mechine in ${container[@]}
	do
		mechine_hi=$(echo $mechine | tr '[a-z]' '[A-Z]')
		mechine_lo=$(echo $mechine | tr '[A-Z]' '[a-z]')
		docker rm -f $mechine_hi
		snow_hi=$(echo $SNOW_LEOPARD | tr '[a-z]' '[A-Z]')
		IP_SNOW_SERVER=`docker inspect --format="{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" $snow_hi |awk '{print $3}'`
		curl -X POST "http://$IP_SNOW_SERVER/Api/Host/Del?site_id=10000&timestamp=1504258467&signature=cdn-live-test-key&host_name=$mechine_lo"
	done
}

function create_transcode {
	transcode_lo=$(echo $TRANSCODE | tr '[A-Z]' '[a-z]')
	transcode_hi=$(echo $TRANSCODE | tr '[a-z]' '[A-Z]')
	echo "transcode_hi : $transcode_hi"
	getunbindport_transcode $TRANSCODE_DOCKER_PORT
	TRANSCODE_DOCKER_HOST_HTTPS=`expr $TRANSCODE_DOCKER_PORT + 1`
	TRANSCODE_DOCKER_HOST_RTMP=`expr $TRANSCODE_DOCKER_PORT + 2`
	snow_hi=$(echo $SNOW_LEOPARD | tr '[a-z]' '[A-Z]')
	snow_ip=`get_ip $snow_hi`	
	relay_vip=$(echo ${level_2[0]} | tr '[a-z]' '[A-Z]')
	IP_RELAY_VIP=`get_ip $relay_vip`
	echo "IP_RELAY_VIP : $IP_RELAY_VIP"
	docker run --name "$transcode_hi" -p "$TRANSCODE_DOCKER_PORT:80" -p "$TRANSCODE_DOCKER_HOST_HTTPS:443" \
		-p "$TRANSCODE_DOCKER_HOST_RTMP:1935" -tid --cap-add ALL --cap-add=SYS_TIME --hostname="${transcode_lo}" \
		-v "$SHARE_DIR:$DOCKER_HOST_SHARE_DIR" $BASE_DOCKER /bin/bash
		
	transcode_ip=`get_ip $transcode_hi`
	echo "transcode_ip : $transcode_ip"
	docker exec "$snow_hi" /bin/bash -c \
		"echo '${transcode_ip} ${DOMAIN_TRANSCODE}' >> /etc/hosts && \
		echo '${transcode_ip} live-biz-internal-test.jcloudcs.com' >> /etc/hosts"
	
	container=(${level_2[@]})
	for mechine in ${container[@]}
	do
		docker exec "$mechine" /bin/bash -c "echo '${transcode_ip} ${DOMAIN_TRANSCODE}' >> /etc/hosts"
	done
	
	docker exec "$transcode_hi" /bin/bash -c \
		"sed -i 's#ZONE=\"UTC\"#ZONE=\"Asia/Shanghai\"#' /etc/sysconfig/clock && \
		sed -i 's#True#false#' /etc/sysconfig/clock && echo 'ARC=false' >> /etc/sysconfig/clock && \
		ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
		yum -y install xz tar lsof && \
		mkdir -p /export/servers/node-v8 && \
		tar -xvf /export/dockershare/live/deploy/node-v8.0.0-linux-x64.tar -C /export/servers/node-v8/ && \
		ln -s /export/servers/node-v8/node-v8.0.0-linux-x64/bin/node /usr/local/bin/node && \
		ln -s /export/servers/node-v8/node-v8.0.0-linux-x64/bin/npm /usr/local/bin/npm && \
		cp -rf /export/dockershare/live/deploy/nodeMock-master /export/servers/ && \
		cp -rf /export/dockershare/live/deploy/srs-transcode/srs_relay_9130  /export/servers/ && \
		chmod +x /export/servers/srs_relay_9130/bin/* && \
		/export/servers/srs_relay_9130/bin/control start && \
		echo '${IP_RELAY_VIP} ${DOMAIN_RELAY_HD}' >> /etc/hosts && \
		echo '${IP_RELAY_VIP} ${DOMAIN_INTERNAL_MIX}' >> /etc/hosts && \
		nohup node /export/servers/nodeMock-master/app.js &"	
}

function remove_transcode {
	docker rm -f $(echo $TRANSCODE | tr '[a-z]' '[A-Z]')
}

function create_compiler {
	mechine_hi=$(echo $COMPILER | tr '[a-z]' '[A-Z]')
	mechine_lo=$(echo $COMPILER | tr '[A-Z]' '[a-z]')
	create_container $mechine_hi $mechine_lo $BASE_DOCKER 127.0.0.1
	docker exec "$mechine_hi" /bin/bash -c \
	"yum -y install tar lsof gcc gcc-c++ patch unzip perl* zlib zlib-devel bzip2-devel libxcb-devel && \
		tar -C /usr/local -xzf ${DOCKER_HOST_SHARE_DIR}go1.10.1.linux-amd64.tar.gz && \
		mkdir -p /home/gopath /export/Logs && \
		echo 'export GOROOT=/usr/local/go' >> /root/.bashrc && \
		echo 'export GOBIN=\$GOROOT/bin' >> /root/.bashrc && \
		echo 'export GOPATH=/home/gopath' >> /root/.bashrc && \
		echo 'export PATH=\$PATH:\$GOBIN:\$GOPATH/bin' >> /root/.bashrc && \
		source /root/.bashrc"
}

function pull_redis {
	docker pull redis
}

function pull_mysql {
	docker pull mysql:5.7
}

function remove_snow {
	docker rm -f $(echo $SNOW_LEOPARD | tr '[a-z]' '[A-Z]') \
		$(echo $SNOW_LEOPARD_REDIS | tr '[a-z]' '[A-Z]') $(echo $SNOW_LEOPARD_MYSQL | tr '[a-z]' '[A-Z]')
}

#build others need call after compiler has been setup before snow & relay & edge
function build_others {
	echo $DOCKER_NAME_SUFFIX
	COMPILER=`docker ps --format "{{.ID}}: {{.Names}}" | grep "$DOCKER_NAME_SUFFIX" | grep "COMPILER"| awk '{print $2}'`
	echo $COMPILER
	mechine_hi=$(echo $COMPILER | tr '[a-z]' '[A-Z]')
	mechine_lo=$(echo $COMPILER | tr '[A-Z]' '[a-z]')
	docker exec "$mechine_hi" /bin/bash -c \
		"source /root/.bashrc && cd ${SHARE_DIR}live/deploy/live-snow-leopard/ && ./build.sh snow-leopard && \
		cd ${SHARE_DIR}live/deploy/live-black-cat/ && sh ./build.sh && \
		cd ${SHARE_DIR}live/deploy/live-golden-cat/ && ./build.sh dev && \
		cd ${SHARE_DIR}live/deploy/live-config-manager/ && ./build.sh"

}

function container_start {
	#启动容器	
	redis_hi=$(echo $SNOW_LEOPARD_REDIS | tr '[a-z]' '[A-Z]')
	mysql_hi=$(echo $SNOW_LEOPARD_MYSQL | tr '[a-z]' '[A-Z]')
	transcode_hi=$(echo $TRANSCODE | tr '[a-z]' '[A-Z]')
	snow_hi=$(echo $SNOW_LEOPARD | tr '[a-z]' '[A-Z]')
	docker start $mysql_hi
	docker start $redis_hi
	docker start $snow_hi
	docker start $transcode_hi
	
	redis_ip=`get_ip $redis_hi`
	mysql_ip=`get_ip $mysql_hi`
	transcode_ip=`get_ip $transcode_hi`
	IP_SNOW_SERVER=`get_ip $snow_hi`
	
	#修改雪豹
	docker exec "${snow_hi}" /bin/bash -c \
		"echo '${redis_ip} ${DOMAIN_SNOW_REDIS}' >> /etc/hosts && \
        echo '${mysql_ip} ${DOMAIN_SNOW_MYSQL}' >> /etc/hosts && \
		echo '${transcode_ip} ${DOMAIN_TRANSCODE}' >> /etc/hosts && \
		echo '${transcode_ip} live-biz-internal-test.jcloudcs.com' >> /etc/hosts && \
		service nginx start && \
		/export/servers/live-snow-leopard/bin/control start"
	sleep 10
	
	#修改relay
	container_relay=(${level_2[@]})
	for mechine in ${container_relay[@]}
	do
		docker start $mechine
		mechine_lo=$(echo $mechine | tr '[A-Z]' '[a-z]')
		mechine_ip=`get_ip $mechine`
		docker exec "${mechine}" /bin/bash -c \
		"echo '${IP_SNOW_SERVER} ${DOMAIN_SNOW_LIVECONFIG}' >> /etc/hosts && \
		echo '${IP_SNOW_SERVER} ${DOMAIN_SNOW_SRS}' >> /etc/hosts && \
		echo '${IP_SNOW_SERVER} ${DOMAIN_SNOW_CENTER}' >> /etc/hosts && \
		echo '${transcode_ip} ${DOMAIN_TRANSCODE}' >> /etc/hosts && \
		sed -i 's/.*AutoHls\"/local request_url  = \"http:\/\/${IP_SNOW_SERVER}\/InnerApi\/Play\/AutoHls\"/' /export/servers/nginx/plugins/lua/jccdn/dynamic_hls/entry.lua && \
		sed -i 's/.*OnPlay\"/local request_url  = \"http:\/\/${IP_SNOW_SERVER}\/InnerApi\/Play\/OnPlay\"/' /export/servers/nginx/plugins/lua/jccdn/base_accesskey/entry.lua && \
		/export/servers/live-black-cat/bin/control start && \
		service crond start && sh /export/dockershare/live/deploy/refresh_crond.sh relay && \
		service nginx start"	

		curl -X POST "http://${IP_SNOW_SERVER}/Api/Host/Update?site_id=10000&timestamp=1504258467&signature=cdn-live-test-key&host_name=${mechine_lo}&cm_ip=${mechine_ip}&ct_ip=${mechine_ip}&uni_ip=${mechine_ip}&default_ip=${mechine_ip}&inner_ip=${mechine_ip}"
		for srs_port in 9135 9136 9137 9138 9139 9230 9231 9232 9233 9234 9235 9236 9237 9238 9239 9335 9336 9337 9338 9339
		do
			srs_dir=/export/servers/srs_relay_$srs_port
			docker exec "${mechine}" /bin/bash -c "$srs_dir/bin/control restart"
		done
		
		for srs_port in 1930 1931 1932 1933 1934
		do
			srs_dir=/export/servers/srs_hls_$srs_port
			docker exec "${mechine}" /bin/bash -c "$srs_dir/bin/control restart"
		done
		
		for srs_port in 1938 1939 9437 9438 9439
		do
			srs_dir=/export/servers/srs_ingest_$srs_port
			docker exec "${mechine}" /bin/bash -c "$srs_dir/bin/control restart"
		done		
	done	
	
	#修改edge
	relay_vip=$(echo ${level_2[0]} | tr '[a-z]' '[A-Z]')
	IP_RELAY_VIP=`docker inspect --format="{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" $relay_vip |awk '{print $3}'`
	`sh $0 dc_host $DOCKER_NAME_SUFFIX`
	container_edge=(${level_1[@]})
	for mechine in ${container_edge[@]}
	do
		docker start $mechine
		mechine_lo=$(echo $mechine | tr '[A-Z]' '[a-z]')
		mechine_ip=`get_ip $mechine`
		docker exec "${mechine}" /bin/bash -c \
		"echo '${IP_SNOW_SERVER} ${DOMAIN_SNOW_LIVECONFIG}' >> /etc/hosts && \
		echo '${IP_SNOW_SERVER} ${DOMAIN_SNOW_SRS}' >> /etc/hosts && \
		echo '${IP_SNOW_SERVER} ${DOMAIN_SNOW_CENTER}' >> /etc/hosts && \
		echo '${IP_RELAY_VIP} ${DOMAIN_RELAY_HD}' >> /etc/hosts && \
		echo '${IP_RELAY_VIP} ${DOMAIN_RELAY_VIP}' >> /etc/hosts && \
		sed -i 's/.*AutoHls\"/local request_url  = \"http:\/\/${IP_SNOW_SERVER}\/InnerApi\/Play\/AutoHls\"/' /export/servers/nginx/plugins/lua/jccdn/dynamic_hls/entry.lua && \
		sed -i 's/.*OnPlay\"/local request_url  = \"http:\/\/${IP_SNOW_SERVER}\/InnerApi\/Play\/OnPlay\"/' /export/servers/nginx/plugins/lua/jccdn/base_accesskey/entry.lua && \
		/export/servers/live-black-cat/bin/control start && \
		service crond start && sh /export/dockershare/live/deploy/refresh_crond.sh edge && \
		service nginx start"	

		curl -X POST "http://${IP_SNOW_SERVER}/Api/Host/Update?site_id=10000&timestamp=1504258467&signature=cdn-live-test-key&host_name=${mechine_lo}&cm_ip=${mechine_ip}&ct_ip=${mechine_ip}&uni_ip=${mechine_ip}&default_ip=${mechine_ip}&inner_ip=${mechine_ip}"
		for srs_port in 1936 1937 1938 1939 9136 9137 9138 9139
		do
			srs_dir=/export/servers/srs_edge_$srs_port
			docker exec "${mechine}" /bin/bash -c "$srs_dir/bin/control restart"
		done
		
		for srs_port in 1931 1932
		do
			srs_dir=/export/servers/srs_l2_ingest_$srs_port
			docker exec "${mechine}" /bin/bash -c "$srs_dir/bin/control restart"
		done
	done
	
	#修改transcode	
	docker exec "${transcode_hi}" /bin/bash -c \
		"/export/servers/srs_relay_9130/bin/control start && \
		echo '${IP_RELAY_VIP} ${DOMAIN_RELAY_HD}' >> /etc/hosts && \
		echo '${IP_RELAY_VIP} ${DOMAIN_INTERNAL_MIX}' >> /etc/hosts && \
		nohup node /export/servers/nodeMock-master/app.js &"
}

function dc_host {
	cd ${SHARE_DIR}live/deploy/
	alias_lo=$(echo $DOCKER_NAME_SUFFIX | tr '[A-Z]' '[a-z]')
	rm ${alias_lo}_dc_hosts.conf
	echo -e "{" >> ${alias_lo}_dc_hosts.conf
	CARRY=""
	for mechine in ${level_1[@]}
	do
		host=`echo ${mechine%%-RTMP*}` 
		mechine_hi=$(echo $mechine | tr '[a-z]' '[A-Z]')
		IP_EDGE=`docker inspect --format="{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" $mechine_hi |awk '{print $3}'`
		if [ "${CARRY}" != "${host}" ];then
			if [ `cat ${alias_lo}_dc_hosts.conf | wc -l` -gt 1 ];then
				lastline=`tail -n 1 ${alias_lo}_dc_hosts.conf`
				sed -i '$d' ${alias_lo}_dc_hosts.conf
				echo -e "${lastline%%,*}" >> ${alias_lo}_dc_hosts.conf
				echo -e "\t}," >> ${alias_lo}_dc_hosts.conf
			fi
			CARRY=${host}
			echo -e "\t\"${CARRY}\":{" >> ${alias_lo}_dc_hosts.conf
			echo -e "\t\t\"${mechine}\":\"${IP_EDGE}\"," >> ${alias_lo}_dc_hosts.conf
			#add idc
			idc_name_lo=$(echo $CARRY | tr '[A-Z]' '[a-z]')
			idc_location=`echo ${idc_name_lo%%-*}`
			snow_hi=$(echo $SNOW_LEOPARD | tr '[a-z]' '[A-Z]')
			IP_SNOW_SERVER=`docker inspect --format="{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" $snow_hi |awk '{print $3}'`
			curl -X POST "http://${IP_SNOW_SERVER}/Api/Idc/Add?site_id=10000&timestamp=1504258467&signature=cdn-live-test-key&idc_name=${idc_name_lo}&cm_vip=${IP_EDGE}&ct_vip=${IP_EDGE}&uni_vip=${IP_EDGE}&inner_vip=${IP_EDGE}&server_location=${idc_location}&idc_type=1&is_l2=1&up_node=${idc_name_lo}&node_level=1&priority=1"
			
		elif [ ${CARRY} == ${host} ];then
			echo -e "\t\t\"${mechine}\":\"${IP_EDGE}\"," >> ${alias_lo}_dc_hosts.conf
		fi
	done
	lastline=`tail -n 1 ${alias_lo}_dc_hosts.conf`
	sed -i '$d' ${alias_lo}_dc_hosts.conf
	echo -e "${lastline%%,*}" >> ${alias_lo}_dc_hosts.conf
	echo -e "\t}\n}" >> ${alias_lo}_dc_hosts.conf
	
	for mechine in ${level_1[@]}
	do
		mechine_hi=$(echo $mechine | tr '[a-z]' '[A-Z]')
		docker exec "$mechine_hi" /bin/bash -c \
		"mv /export/servers/live-config-manager/conf_data/dc_hosts.conf /export/servers/live-config-manager/conf_data/dc_hosts.conf.bak && \		
		cp /export/dockershare/live/deploy/${alias_lo}_dc_hosts.conf /export/servers/live-config-manager/conf_data/dc_hosts.conf && \
		service nginx start"
	done
}



case "${1}" in
relay)
	create_relay
	;;
edge)
	create_edge
	;;
snow)
	create_snow
	;;
transcode)
	create_transcode
	;;
container_start)
	container_start
	;;
pull)
	pull_redis
	pull_mysql
	;;
rm_snow)
	remove_snow
	;;
rm_relay)
	remove_relay
	;;
rm_edge)
	remove_edge
	;;
rm_transcode)
	remove_transcode
	;;
compiler)
	create_compiler
	;;
build_others)
	build_others $2
	;;
dc_host)
	dc_host
	;;
*)
	help
	;;
esac

