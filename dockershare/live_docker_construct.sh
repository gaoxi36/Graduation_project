#!/bin/bash
#前提条件
#1.物理机安装有Docker容器且拉取镜像centos:6.6
#2.物理机/export/dockershare/ 下放置此脚本
#3.物理机/export/dockershare/ 下有Srs及Nginx安装包
#4.物理机/export/dockershare/conf 下有标准配置文件srs.conf及nginx.conf
#5.物理机/export/dockershare/yum_packages/ 下有rpm离线安装包
#6.物理机文件夹/export/dockershare/与Docker容器通过文件夹映射以减少空间占用
#7.请先构建relay再构建edge且同组的relay和edge昵称保持一致

if [ $# -lt 2 ]; then
        echo "USAGE: $0 LIVE_ROLE SYSTEM_ALIAS"
        echo "e.g.: $0 help ob767"
        exit 1;
fi

#帮助
function help {
	echo "${0} <help|relay|edge|rm_relay|rm_edge> <alias>"
}

#物理机文件夹及Docker容器文件夹目录
readonly SHARE_DIR="/export/dockershare/"
readonly DOCKER_SHARE_DIR="/export/dockershare/"

#Docker容器镜像名
readonly BASE_DOCKER="centos:6.6"

#Docker容器映射端口
SRS_DOCKER_EDGE_PORT=30000
SRS_DOCKER_RELAY_PORT=40000
SRS_DOCKER_RTMP_PORT=1935
SRS_DOCKER_HTTP_PORT=80
SRS_DOCKER_HTTPS_PORT=443

#各个Docker容器将统一后缀为SYSTEM_ALIAS
NAME=$2
DOCKER_NAME=$(echo $NAME | tr '[a-z]' '[A-Z]')

#中转服务器命名规则 地域(省份)-昵称-RELAY-编号
#边缘服务器命名规则 地域(省会)-昵称-EDGE-编号
relay_name=("BJ-$DOCKER_NAME-RELAY")
edge_name=("BJ-$DOCKER_NAME-EDGE-1" "TJ-$DOCKER_NAME-EDGE-2" "SH-$DOCKER_NAME-EDGE-3" "CQ-$DOCKER_NAME-EDGE-4" "SJZ-$DOCKER_NAME-EDGE-5" "TY-$DOCKER_NAME-EDGE-6" "SY-$DOCKER_NAME-EDGE-7" "CC-$DOCKER_NAME-EDGE-8" "HEB-$DOCKER_NAME-EDGE-9" "NJ-$DOCKER_NAME-EDGE-10" "HZ-$DOCKER_NAME-EDGE-11" "HF-$DOCKER_NAME-EDGE-12" "FZ-$DOCKER_NAME-EDGE-13" "NC-$DOCKER_NAME-EDGE-14" "JN-$DOCKER_NAME-EDGE-15" "ZZ-$DOCKER_NAME-EDGE-16" "WH-$DOCKER_NAME-EDGE-17" "CS-$DOCKER_NAME-EDGE-18" "GZ-$DOCKER_NAME-EDGE-19" "HK-$DOCKER_NAME-EDGE-20" "CD-$DOCKER_NAME-EDGE-21" "GY-$DOCKER_NAME-EDGE-22" "KM-$DOCKER_NAME-EDGE-23" "XA-$DOCKER_NAME-EDGE-24" "LZ-$DOCKER_NAME-EDGE-25")

#端口号确认函数
function getport_relay {
        local LOCAL_1=$1
        lsof -i:$LOCAL_1 >> /dev/null
        if [ $? -eq 1 ]; then
                lsof -i:`expr $LOCAL_1 + 1` >> /dev/null
                if [ $? -eq 1 ]; then
                        lsof -i:`expr $LOCAL_1 + 2` >> /dev/null
                        if [ $? -eq 1 ]; then
                                SRS_DOCKER_RELAY_PORT=$LOCAL_1
                        else
                                getport_relay `expr $LOCAL_1 + 100`
                        fi
                else
                        getport_relay `expr $LOCAL_1 + 100`
                fi
        else
                getport_relay `expr $LOCAL_1 + 100`
        fi
}

function getport_edge {
        local LOCAL_1=$1
        lsof -i:$LOCAL_1 >> /dev/null
        if [ $? -eq 1 ]; then
                lsof -i:`expr $LOCAL_1 + 1` >> /dev/null
                if [ $? -eq 1 ]; then
                        lsof -i:`expr $LOCAL_1 + 2` >> /dev/null
                        if [ $? -eq 1 ]; then
                                SRS_DOCKER_EDGE_PORT=$LOCAL_1
                        else
                                getport_edge `expr $LOCAL_1 + 100`
                        fi
                else
                        getport_edge `expr $LOCAL_1 + 100`
                fi
        else
                getport_edge `expr $LOCAL_1 + 100`
        fi
}

#搭建Docker容器函数
function create_relay {
        container=(${relay_name[@]})

        for relay in ${container[@]}
        do
                relay_lo=$(echo $relay | tr '[A-Z]' '[a-z]')
                relay_hi=$(echo $relay | tr '[a-z]' '[A-Z]')
		getport_relay $SRS_DOCKER_RELAY_PORT
		local LOCAL_PORT1=`expr $SRS_DOCKER_RELAY_PORT + 1`
		local LOCAL_PORT2=`expr $SRS_DOCKER_RELAY_PORT + 2`
		docker run --name "${relay_hi}" -tid --cap-add=SYS_TIME --cap-add ALL --net bridge --hostname="${relay_lo}" -v "${SHARE_DIR}:${DOCKER_SHARE_DIR}" -p "${SRS_DOCKER_RELAY_PORT}:${SRS_DOCKER_RTMP_PORT}" -p "${LOCAL_PORT1}:${SRS_DOCKER_HTTP_PORT}" -p "${LOCAL_PORT2}:${SRS_DOCKER_HTTPS_PORT}" ${BASE_DOCKER} /bin/bash
		docker exec "${relay_hi}" /bin/bash -c \
		"sed -i 's#ZONE=\"UTC\"#ZONE=\"Asia/Shanghai\"#' /etc/sysconfig/clock
		sed -i 's#True#false#' /etc/sysconfig/clock
		echo 'ARC=false' >> /etc/sysconfig/clock
		ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
		#现在不再采用yum安装为节约时间采用rpm安装包离线安装
		#yum install -y lsb gcc zlib zlib-devel pcre pcre-devel
		cd /export/dockershare/yum_packages/
		rpm -ivh ./*.rpm --nodeps --force
		cp -rf /export/dockershare/SRS/ /export/
		bash /export/SRS/INSTALL
		cp -rf /export/dockershare/nginx/ /export/
		cd /export/nginx/
		bash /export/nginx/configure
		make && make install
		mv -f /usr/local/srs/conf/srs.conf /usr/local/srs/conf/srs.conf.old
		mv -f /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.old
		cp /export/dockershare/conf/srs_relay.conf /usr/local/srs/conf/srs.conf
		cp /export/dockershare/conf/nginx_relay.conf /usr/local/nginx/conf/nginx.conf
		cd /usr/local/nginx
		./sbin/nginx -c ./conf/nginx.conf
		service srs start
		service crond start
        	crontab crontab_conf"
	done
}

function create_edge {
        container=(${edge_name[@]})

        for edge in ${container[@]}
        do
                edge_lo=$(echo $edge | tr '[A-Z]' '[a-z]')
                edge_hi=$(echo $edge | tr '[a-z]' '[A-Z]')
                getport_edge $SRS_DOCKER_EDGE_PORT
                local LOCAL_PORT1=`expr $SRS_DOCKER_EDGE_PORT + 1`
                local LOCAL_PORT2=`expr $SRS_DOCKER_EDGE_PORT + 2`
		RELAY_IP=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' BJ-$DOCKER_NAME-RELAY`
                docker run --name "${edge_hi}" -tid --cap-add=SYS_TIME --cap-add ALL --net bridge --hostname="${edge_lo}" -v "${SHARE_DIR}:${DOCKER_SHARE_DIR}" -p "${SRS_DOCKER_EDGE_PORT}:${SRS_DOCKER_RTMP_PORT}" -p "${LOCAL_PORT1}:${SRS_DOCKER_HTTP_PORT}" -p "${LOCAL_PORT2}:${SRS_DOCKER_HTTPS_PORT}" ${BASE_DOCKER} /bin/bash
		docker exec "${edge_hi}" /bin/bash -c \
                "sed -i 's#ZONE=\"UTC\"#ZONE=\"Asia/Shanghai\"#' /etc/sysconfig/clock
                sed -i 's#True#false#' /etc/sysconfig/clock
                echo 'ARC=false' >> /etc/sysconfig/clock
                ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
		#现在不再采用yum安装为节约时间采用rpm安装包离线安装
                #yum install -y lsb gcc zlib zlib-devel pcre pcre-devel
                cd /export/dockershare/yum_packages/
                rpm -ivh ./*.rpm --nodeps --force
                cp -rf /export/dockershare/SRS/ /export/
                bash /export/SRS/INSTALL
                cp -rf /export/dockershare/nginx/ /export/
                cd /export/nginx/
                bash /export/nginx/configure
                make && make install
                mv -f /usr/local/srs/conf/srs.conf /usr/local/srs/conf/srs.conf.old
                mv -f /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.old
                cp /export/dockershare/conf/srs_edge.conf /usr/local/srs/conf/srs.conf
                cp /export/dockershare/conf/nginx_edge.conf /usr/local/nginx/conf/nginx.conf
		sed -i 's/767.767.767.767/${RELAY_IP}/g' /usr/local/srs/conf/srs.conf
		sed -i 's/767.767.767.767/${RELAY_IP}/g' /usr/local/nginx/conf/nginx.conf
                cd /usr/local/nginx
                ./sbin/nginx -c ./conf/nginx.conf
                service srs start"
        done
}

#删除Docker容器函数
function remove_relay {
	container=(${relay_name[@]})
	for relay in ${container[@]}
	do
		relay_hi=$(echo $relay | tr '[a-z]' '[A-Z]')
		relay_lo=$(echo $relay | tr '[A-Z]' '[a-z]')
		docker rm -f $relay_hi
	done
}

function remove_edge {
        container=(${edge_name[@]})
        for edge in ${container[@]}
        do
                edge_hi=$(echo $edge | tr '[a-z]' '[A-Z]')
                edge_lo=$(echo $edge | tr '[A-Z]' '[a-z]')
                docker rm -f $edge_hi
        done
}

case "${1}" in
relay)
	create_relay
	;;
edge)
	create_edge
	;;
rm_relay)
	remove_relay
	;;
rm_edge)
	remove_edge
	;;
*)
	help
	;;
esac
