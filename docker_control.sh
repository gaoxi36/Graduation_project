#!/bin/bash

NAME=$2
DOCKER_NAME=$(echo $NAME | tr '[a-z]' '[A-Z]') # 集群名称

if [ $# -lt 2 ] ; then 
	echo "USAGE: $0 LIVE_ROLE SYSTEM_ALIAS" 
	echo " e.g.: $0 start CACTUS" 
	exit 1; 
fi

DOCKER_REDIS_NAME="live-redis-hb3.jcloud.com"
DOCKER_MYSQL_NAME="test.database.env-jcloud-cdn.com"
DOCKER_EDGE_ID=`docker ps -aqf 'name='$DOCKER_NAME'-RTMP'`
DOCKER_RELAY_ID=`docker ps -aqf 'name='$DOCKER_NAME'-RELAY'`
DOCKER_REDIS_ID=`docker ps -aqf 'name=REDIS.'$DOCKER_NAME''`
DOCKER_MYSQL_ID=`docker ps -aqf 'name=MYSQL.'$DOCKER_NAME''`
DOCKER_SNOW_ID=`docker ps -aqf 'name=SNOWLEOPARD.'$DOCKER_NAME''`
DOCKER_TRANSCODE_ID=`docker ps -aqf 'name=TRANSCODE.'$DOCKER_NAME''`

help(){
    echo "${0} <start|stop|restart|update>"
    exit 1
}

start(){
    docker start $DOCKER_REDIS_ID
    docker start $DOCKER_MYSQL_ID
    docker start $DOCKER_SNOW_ID
    docker start $DOCKER_TRANSCODE_ID
    DOCKER_REDIS_IP=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' LIVE-SNOW-REDIS.${DOCKER_NAME}`
    DOCKER_MYSQL_IP=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' LIVE-SNOW-MYSQL.${DOCKER_NAME}`
    DOCKER_SNOW_IP=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' LIVE-SNOWLEOPARD.${DOCKER_NAME}`
    DOCKER_TRANSCODE_IP=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' LIVE-TRANSCODE.${DOCKER_NAME}`
    docker exec $DOCKER_SNOW_ID /bin/bash -c \
	"echo '${DOCKER_REDIS_IP} ${DOCKER_REDIS_NAME}' >> /etc/hosts
	echo '${DOCKER_MYSQL_IP} ${DOCKER_MYSQL_NAME}' >> /etc/hosts
	echo '${DOCKER_TRANSCODE_IP} live-transpond-online.jdcloud.com' >> /etc/hosts
	echo '${DOCKER_TRANSCODE_IP} live-biz-internal-test.jcloudcs.com' >> /etc/hosts
	service nginx start
	service crond start
	/export/servers/live-snow-leopard/bin/control start
	sh /export/dockershare/live/deploy/refresh_crond.sh snow"
    sleep 15s
    for RELAY in ${DOCKER_RELAY_ID[@]}
    do
	docker start $RELAY
	DOCKER_RELAY_IP=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' $RELAY`
	DOCKER_RELAY_NAME=`docker inspect --format '{{ .Name }}' $RELAY`
	DOCKER_RELAY_NAME=${DOCKER_RELAY_NAME#*/}
	DOCKER_RELAY_NAME=$(echo $DOCKER_RELAY_NAME | tr '[A-Z]' '[a-z]')
	curl -X POST "http://${DOCKER_SNOW_IP}/Api/Host/Update?site_id=10000&timestamp=1504258467&signature=cdn-live-test-key&host_name=$DOCKER_RELAY_NAME&cm_ip=$DOCKER_RELAY_IP&ct_ip=$DOCKER_RELAY_IP&uni_ip=$DOCKER_RELAY_IP&default_ip=$DOCKER_RELAY_IP&inner_ip=$DOCKER_RELAY_IP"
	docker exec $RELAY /bin/bash -c \
	    "echo '${DOCKER_SNOW_IP} live.jcloud.com' >> /etc/hosts
	    echo '${DOCKER_SNOW_IP} live-inner.jcloud.com' >> /etc/hosts
	    echo '${DOCKER_SNOW_IP} live-center.jdcloud.com' >> /etc/hosts
	    echo '${DOCKER_TRANSCODE_IP} live-transpond-online.jdcloud.com' >> /etc/hosts
	    echo '${DOCKER_RELAY_IP} live-center.v.jdcloud.com' >> /etc/hosts
	    echo '${DOCKER_RELAY_IP} mt-live-timeshift-hb.jdcloud.com' >> /etc/hosts
	    rm /export/servers/nginx/plugins/lua/jccdn/dynamic_hls/entry.lua
	    rm /export/servers/nginx/plugins/lua/jccdn/base_accesskey/entry.lua
	    cp /export/dockershare/lua/dynamic_hls/entry.lua /export/servers/nginx/plugins/lua/jccdn/dynamic_hls/
	    cp /export/dockershare/lua/base_accesskey/entry.lua /export/servers/nginx/plugins/lua/jccdn/base_accesskey/
	    sed -i 's/767.767.767.767/${DOCKER_SNOW_IP}/g' /export/servers/nginx/plugins/lua/jccdn/dynamic_hls/entry.lua
	    sed -i 's/767.767.767.767/${DOCKER_SNOW_IP}/g' /export/servers/nginx/plugins/lua/jccdn/base_accesskey/entry.lua
	    sh /export/dockershare/start_srs.sh"
	docker exec $RELAY /bin/bash -c \
            "service crond start
	    service nginx start
            sh /export/dockershare/live/deploy/refresh_crond.sh relay"
    done
    DOCKER_HB_IP=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' YF-${DOCKER_NAME}-RELAY-1`
    DOCKER_JN_IP=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' JN-${DOCKER_NAME}-RELAY-1`
    for EDGE in ${DOCKER_EDGE_ID[@]}
    do
	docker start $EDGE
	DOCKER_EDGE_IP=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' $EDGE`
        DOCKER_EDGE_NAME=`docker inspect --format '{{ .Name }}' $EDGE`
        DOCKER_EDGE_NAME=${DOCKER_EDGE_NAME#*/}
        DOCKER_EDGE_NAME=$(echo $DOCKER_EDGE_NAME | tr '[A-Z]' '[a-z]')
        curl -X POST "http://${DOCKER_SNOW_IP}/Api/Host/Update?site_id=10000&timestamp=1504258467&signature=cdn-live-test-key&host_name=$DOCKER_EDGE_NAME&cm_ip=$DOCKER_EDGE_IP&ct_ip=$DOCKER_EDGE_IP&uni_ip=$DOCKER_EDGE_IP&default_ip=$DOCKER_EDGE_IP&inner_ip=$DOCKER_EDGE_IP"
	docker exec $EDGE /bin/bash -c \
	    "echo '${DOCKER_EDGE_IP} hd-origin.jdcloud.com' >> /etc/hosts
	    echo '${DOCKER_SNOW_IP} live.jcloud.com' >> /etc/hosts
	    echo '${DOCKER_SNOW_IP} live-inner.jcloud.com' >> /etc/hosts
	    echo '${DOCKER_SNOW_IP} live-center.jdcloud.com' >> /etc/hosts
	    echo '${DOCKER_HB_IP} hb-origin.jdcloud.com' >> /etc/hosts
	    echo '${DOCKER_JN_IP} jn-origin.jdcloud.com' >> /etc/hosts
	    echo '${DOCKER_HB_IP} origin.jcloud.com' >> /etc/hosts
	    rm /export/servers/nginx/plugins/lua/jccdn/dynamic_hls/entry.lua
            rm /export/servers/nginx/plugins/lua/jccdn/base_accesskey/entry.lua
            cp /export/dockershare/lua/dynamic_hls/entry.lua /export/servers/nginx/plugins/lua/jccdn/dynamic_hls/
            cp /export/dockershare/lua/base_accesskey/entry.lua /export/servers/nginx/plugins/lua/jccdn/base_accesskey/
            sed -i 's/767.767.767.767/${DOCKER_SNOW_IP}/g' /export/servers/nginx/plugins/lua/jccdn/dynamic_hls/entry.lua
            sed -i 's/767.767.767.767/${DOCKER_SNOW_IP}/g' /export/servers/nginx/plugins/lua/jccdn/base_accesskey/entry.lua
	    sh /export/dockershare/start_srs.sh"
	docker exec $EDGE /bin/bash -c \
	    "service crond start
	    service nginx start
	    sh /export/dockershare/live/deploy/refresh_crond.sh edge"
    done
    docker exec $DOCKER_TRANSCODE_ID /bin/bash -c \
	"echo '${DOCKER_HB_IP} hb-origin.jdcloud.com' >> /etc/hosts
        echo '${DOCKER_HB_IP} test-internal-mix.push.jcloud.com' >> /etc/hosts
	/export/servers/srs_relay_9130/bin/control start
	nohup node /export/servers/nodeMock-master/app.js &"
}

update_conf(){
    for RELAY in ${DOCKER_RELAY_ID[@]}
    do 
	DOCKER_RELAY_NAME=`docker inspect --format '{{ .Name }}' $RELAY`
	echo ${DOCKER_RELAY_NAME}:update_conf begin
	docker exec $RELAY /bin/bash -c \
	    "php /export/servers/live-config-manager/srs_vhost_conf_update.php relay 1
	    php /export/servers/live-config-manager/srs_vhost_conf_update.php hls 1
	    php /export/servers/live-config-manager/srs_vhost_conf_update.php ingest 1
	    php /export/servers/live-config-manager/nginx_vhost_conf_update.php relay 1
	    "
	echo ${DOCKER_RELAY_NAME}:update_conf over
    done
    for EDGE in ${DOCKER_EDGE_ID[@]}
    do
        DOCKER_EDGE_NAME=`docker inspect --format '{{ .Name }}' $EDGE`
        echo ${DOCKER_EDGE_NAME}:update_conf begin
        docker exec $EDGE /bin/bash -c \
            "php /export/servers/live-config-manager/srs_vhost_conf_update.php edge 1
            php /export/servers/live-config-manager/srs_vhost_conf_update.php l2_ingest 1
	    php /export/servers/live-config-manager/nginx_vhost_conf_update.php edge 1
            "
        echo ${DOCKER_EDGE_NAME}:update_conf over
    done
}

stop(){
    docker stop $DOCKER_REDIS_ID
    docker stop $DOCKER_MYSQL_ID
    docker stop $DOCKER_SNOW_ID
    for RELAY in ${DOCKER_RELAY_ID[@]}
    do
	docker stop $RELAY
    done
    for EDGE in ${DOCKER_EDGE_ID[@]}
    do
	docker stop $EDGE
    done
    docker stop $DOCKER_TRANSCODE_ID
}

case "${1}" in
    start)
        start
	;;
    stop)
        stop
        ;;
    update)
	update_conf
	;;
    restart)
        stop && start
        ;;
    *)
        help
        ;;
esac
