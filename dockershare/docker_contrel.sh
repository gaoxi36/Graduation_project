#!/bin/bash
#前提条件
#1.直播流媒体服务器已经由live_docker_construct脚本搭建完成
#2.请使用docker ps -a查看已经搭建的集群昵称

if [ $# -lt 2 ]; then
        echo "USAGE: $0 LIVE_ROLE SYSTEM_ALIAS"
        echo "e.g.: $0 help ob767"
        exit 1;
fi

#帮助
function help {
	echo "${0} <help|start|stop|restart> <alias>"
}

#集群Docker容器昵称
NAME=$2
DOCKER_NAME=$(echo $NAME | tr '[a-z]' '[A-Z]')

#集群容器ID
DOCKER_RELAY_ID=`docker ps -aqf 'name='$DOCKER_NAME'-RELAY'`
DOCKER_EDGE_ID=`docker ps -aqf 'name='$DOCKER_NAME'-EDGE'`

#启动集群服务函数
function docker_start {
	relay_name=`docker inspect --format '{{ .Name }}' $DOCKER_RELAY_ID`
	docker start $DOCKER_RELAY_ID
	DOCKER_RELAY_IP=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' $DOCKER_RELAY_ID`
	docker exec $DOCKER_RELAY_ID /bin/bash -c \
	"cd /usr/local/nginx
	./sbin/nginx -c ./conf/nginx.conf
	service srs start
	service crond start
	crontab crontab_conf
	echo '${relay_name} is already start'"
	for edge in ${DOCKER_EDGE_ID[@]}
	do
		edge_name=`docker inspect --format '{{ .Name }}' $edge`
		docker start $edge
		docker exec $edge /bin/bash -c \
		"mv -f /usr/local/srs/conf/srs.conf /usr/local/srs/conf/srs.conf.old
                mv -f /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.old
                cp /export/dockershare/conf/srs_edge.conf /usr/local/srs/conf/srs.conf
                cp /export/dockershare/conf/nginx_edge.conf /usr/local/nginx/conf/nginx.conf
		sed -i 's/767.767.767.767/${DOCKER_RELAY_IP}/g' /usr/local/srs/conf/srs.conf
		sed -i 's/767.767.767.767/${DOCKER_RELAY_IP}/g' /usr/local/nginx/conf/nginx.conf
                cd /usr/local/nginx
                ./sbin/nginx -c ./conf/nginx.conf
                service srs start
		echo '${edge_name} is already start'"
	done
	echo "service start OK"
}

#停止集群服务函数
function docker_stop {
	relay_name=`docker inspect --format '{{ .Name }}' $DOCKER_RELAY_ID`
	docker stop $DOCKER_RELAY_ID
	echo "${relay_name} is stop"
	for edge in ${DOCKER_EDGE_ID[@]}
        do
		edge_name=`docker inspect --format '{{ .Name }}' $edge`
                docker stop $edge
		echo "${edge_name} is stop"
	done
	echo "service stop OK"
}

case "${1}" in
start)
	docker_start
	;;
stop)
        docker_stop
        ;;
restart)
        docker_stop && docker_start
        ;;
*)
	help
        ;;
esac
