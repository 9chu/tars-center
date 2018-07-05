#!/bin/bash
set -e
source /etc/profile

# 创建日志目录
if [ ! -d /data/log ]; then
    mkdir -p /data/log
fi

if [ ! -d /data/log/tars ]; then
    mkdir -p /data/log/tars
fi

if [ ! -d /data/log/app_log ]; then
    mkdir -p /data/log/app_log
fi

if [ ! -d /data/log/remote_app_log ]; then
    mkdir -p /data/log/remote_app_log
fi

if [ ! -d /usr/local/app/tars/app_log ]; then
    ln -s /data/log/app_log /usr/local/app/tars/app_log
fi

if [ ! -d /usr/local/app/tars/remote_app_log ]; then
    ln -s /data/log/remote_app_log /usr/local/app/tars/remote_app_log
fi

# 创建数据目录
if [ ! -d /data/tars ]; then
    mkdir -p /data/tars
fi

if [ ! -d /data/tars/data ]; then
    mkdir -p /data/tars/data
fi

if [ ! -d /data/tars/data/tarsconfig ]; then
    mkdir -p /data/tars/data/tarsconfig
fi

if [ ! -d /data/tars/data/tarspatch ]; then
    mkdir -p /data/tars/data/tarspatch
fi

if [ ! -d /data/tars/data/tarsregistry ]; then
    mkdir -p /data/tars/data/tarsregistry
fi

if [ ! -d /usr/local/app/tars/tarsconfig/data ]; then
    ln -s /data/tars/data/tarsconfig /usr/local/app/tars/tarsconfig/data
fi

if [ ! -d /usr/local/app/tars/tarspatch/data ]; then
    ln -s /data/tars/data/tarspatch /usr/local/app/tars/tarspatch/data
fi

if [ ! -d /usr/local/app/tars/tarsregistry/data ]; then
    ln -s /data/tars/data/tarsregistry /usr/local/app/tars/tarsregistry/data
fi

# 创建节点目录
if [ ! -d /data/node ]; then
    mkdir -p /data/node
fi

if [ ! -d /usr/local/app/tars/tarsnode/data ]; then
    ln -s /data/node /usr/local/app/tars/tarsnode/data
fi

# 创建补丁目录
if [ ! -d /data/patch ]; then
    mkdir -p /data/patch
fi
if [ ! -d /usr/local/app/patchs ]; then
    ln -s /data/patch /usr/local/app/patchs
fi

# 拷贝安装包
if [ ! -d /data/install ]; then
    echo "Copying base service install packages..."
    mkdir -p /data/install
    cp /root/source/Tars/cpp/build/tars*.tgz /data/install/
fi

# 启动OPENVPN
if [ ${OPENVPN_ENABLE} -ne 0 ]; then
    echo "Starting openvpn..."
    mkdir -p /dev/net
    if [ ! -c /dev/net/tun ]; then
        mknod /dev/net/tun c 10 200
    fi
    openvpn --daemon --config ${OPENVPN_CONFIG} --log-append ${OPENVPN_LOG}

    echo "Waitting network device..."
    n=0
    until [ $n -ge 5 ]
    do
        LOCAL_IP=$(ip addr | grep inet | grep ${TARS_BIND_INTERFACE} | awk '{print $2;}' | sed 's|/.*$||')
        if [[ -z "$LOCAL_IP" ]]; then
            echo "Network device is not ready"
            sleep 1
        else
            break
        fi
        n=$[$n+1]
    done
fi

# 获取本机信息
LOCAL_IP=$(ip addr | grep inet | grep ${TARS_BIND_INTERFACE} | awk '{print $2;}' | sed 's|/.*$||')
if [[ -z "$LOCAL_IP" ]]; then
    (>&2 echo "ERROR: Cannot retrieve IP address")
    exit 1
fi

# 初始化数据库
DBCALL="mysql -h${TARS_DB_HOST} -P${TARS_DB_PORT} -u${TARS_DB_USER} -p${TARS_DB_PASS}"
$DBCALL -e "CREATE DATABASE IF NOT EXISTS db_tars;"
$DBCALL -e "CREATE DATABASE IF NOT EXISTS tars_stat;"
$DBCALL -e "CREATE DATABASE IF NOT EXISTS tars_property;"
cat /root/source/Tars/cpp/framework/sql/db_tars.sql | sed -r "s/DROP TABLE/-- DROP TABLE/g" | sed -r "s/CREATE TABLE/CREATE TABLE IF NOT EXISTS/g" | sed -r "s/INSERT INTO/REPLACE INTO/g" | sed -r "s/192.168.2.131/${LOCAL_IP}/g" | sed -r "s/db.tars.com/${TARS_DB_HOST}/g" | $DBCALL db_tars

TARS_REGISTRY_HOST="${LOCAL_IP}"
TARS_REGISTRY_PORT=17890

# 替换配置
sed -i -r "s/localip\s*=\s*.*/localip=${LOCAL_IP}/g" /usr/local/app/tars/tarsAdminRegistry/conf/*
sed -i -r "s/endpoint\s*=\s*tcp\s+-h\s+\S*\s+-p/endpoint=tcp -h ${LOCAL_IP} -p/g" /usr/local/app/tars/tarsAdminRegistry/conf/*
sed -i -r "s/locator\s*=\s*tars.tarsregistry.QueryObj@tcp\s+-h\s+\S*\s+-p\s+.*/locator=tars.tarsregistry.QueryObj@tcp -h ${TARS_REGISTRY_HOST} -p ${TARS_REGISTRY_PORT}/g" /usr/local/app/tars/tarsAdminRegistry/conf/*
sed -i -r "s/dbhost\s*=\s*.*/dbhost=${TARS_DB_HOST}/g" /usr/local/app/tars/tarsAdminRegistry/conf/*
sed -i -r "s/dbuser\s*=\s*.*/dbuser=${TARS_DB_USER}/g" /usr/local/app/tars/tarsAdminRegistry/conf/*
sed -i -r "s/dbpass\s*=\s*.*/dbpass=${TARS_DB_PASS}/g" /usr/local/app/tars/tarsAdminRegistry/conf/*
sed -i -r "s/dbport\s*=\s*.*/dbport=${TARS_DB_PORT}/g" /usr/local/app/tars/tarsAdminRegistry/conf/*

sed -i -r "s/localip\s*=\s*.*/localip=${LOCAL_IP}/g" /usr/local/app/tars/tarsconfig/conf/*
sed -i -r "s/endpoint\s*=\s*tcp\s+-h\s+\S*\s+-p/endpoint=tcp -h ${LOCAL_IP} -p/g" /usr/local/app/tars/tarsconfig/conf/*
sed -i -r "s/locator\s*=\s*tars.tarsregistry.QueryObj@tcp\s+-h\s+\S*\s+-p\s+.*/locator=tars.tarsregistry.QueryObj@tcp -h ${TARS_REGISTRY_HOST} -p ${TARS_REGISTRY_PORT}/g" /usr/local/app/tars/tarsconfig/conf/*
sed -i -r "s/node\s*=\s*tars.tarsnode.ServerObj@tcp\s+-h\s+\S*\s+-p/node=tars.tarsnode.ServerObj@tcp -h ${LOCAL_IP} -p/g" /usr/local/app/tars/tarsconfig/conf/*
sed -i -r "s/dbhost\s*=\s*.*/dbhost=${TARS_DB_HOST}/g" /usr/local/app/tars/tarsconfig/conf/*
sed -i -r "s/dbuser\s*=\s*.*/dbuser=${TARS_DB_USER}/g" /usr/local/app/tars/tarsconfig/conf/*
sed -i -r "s/dbpass\s*=\s*.*/dbpass=${TARS_DB_PASS}/g" /usr/local/app/tars/tarsconfig/conf/*
sed -i -r "s/dbport\s*=\s*.*/dbport=${TARS_DB_PORT}/g" /usr/local/app/tars/tarsconfig/conf/*

sed -i -r "s/localip\s*=\s*.*/localip=${LOCAL_IP}/g" /usr/local/app/tars/tarsregistry/conf/*
sed -i -r "s/endpoint\s*=\s*tcp\s+-h\s+\S*\s+-p/endpoint=tcp -h ${LOCAL_IP} -p/g" /usr/local/app/tars/tarsregistry/conf/*
sed -i -r "s/locator\s*=\s*tars.tarsregistry.QueryObj@tcp\s+-h\s+\S*\s+-p\s+.*/locator=tars.tarsregistry.QueryObj@tcp -h ${TARS_REGISTRY_HOST} -p ${TARS_REGISTRY_PORT}/g" /usr/local/app/tars/tarsregistry/conf/*
sed -i -r "s/dbhost\s*=\s*.*/dbhost=${TARS_DB_HOST}/g" /usr/local/app/tars/tarsregistry/conf/*
sed -i -r "s/dbuser\s*=\s*.*/dbuser=${TARS_DB_USER}/g" /usr/local/app/tars/tarsregistry/conf/*
sed -i -r "s/dbpass\s*=\s*.*/dbpass=${TARS_DB_PASS}/g" /usr/local/app/tars/tarsregistry/conf/*
sed -i -r "s/dbport\s*=\s*.*/dbport=${TARS_DB_PORT}/g" /usr/local/app/tars/tarsregistry/conf/*

sed -i -r "s/localip\s*=\s*.*/localip=${LOCAL_IP}/g" /usr/local/app/tars/tarspatch/conf/*
sed -i -r "s/endpoint\s*=\s*tcp\s+-h\s+\S*\s+-p/endpoint=tcp -h ${LOCAL_IP} -p/g" /usr/local/app/tars/tarspatch/conf/*
sed -i -r "s/locator\s*=\s*tars.tarsregistry.QueryObj@tcp\s+-h\s+\S*\s+-p\s+.*/locator=tars.tarsregistry.QueryObj@tcp -h ${TARS_REGISTRY_HOST} -p ${TARS_REGISTRY_PORT}/g" /usr/local/app/tars/tarspatch/conf/*
sed -i -r "s/node\s*=\s*tars.tarsnode.ServerObj@tcp\s+-h\s+\S*\s+-p/node=tars.tarsnode.ServerObj@tcp -h ${LOCAL_IP} -p/g" /usr/local/app/tars/tarspatch/conf/*
sed -i -r "s/rsync\s+--address=\S*\s+/rsync --address=${LOCAL_IP} /g" /usr/local/app/tars/tarspatch/util/init.sh

sed -i -r "s/locator\s*=\s*tars.tarsregistry.QueryObj@tcp\s+-h\s+\S*\s+-p\s+.*/locator=tars.tarsregistry.QueryObj@tcp -h ${TARS_REGISTRY_HOST} -p ${TARS_REGISTRY_PORT}/g" /usr/local/app/tars/tarsnode/conf/tarsnode.conf
sed -i -r "s/localip\s*=\s*.*/localip=${LOCAL_IP}/g" /usr/local/app/tars/tarsnode/conf/tarsnode.conf
sed -i -r "s/endpoint\s*=\s*tcp\s+-h\s+\S*\s+-p/endpoint=tcp -h ${LOCAL_IP} -p/g" /usr/local/app/tars/tarsnode/conf/tarsnode.conf

# 拉起核心框架服务
echo "Starting core services..."
chmod u+x /usr/local/app/tars/tarsAdminRegistry/util/*.sh
chmod u+x /usr/local/app/tars/tarsconfig/util/*.sh
chmod u+x /usr/local/app/tars/tarsnode/util/*.sh
chmod u+x /usr/local/app/tars/tarspatch/util/*.sh
chmod u+x /usr/local/app/tars/tarsregistry/util/*.sh
chmod u+x /usr/local/app/tars/tars_install.sh && sync && /usr/local/app/tars/tars_install.sh

# 拉起RSYNC
echo "Starting rsync..."
/usr/local/app/tars/tarspatch/util/init.sh

# 拉起tarsnode
echo "Starting tarsnode..."
chmod u+x /usr/local/app/tars/tarsnode/util/*.sh
chmod u+x /usr/local/app/tars/tarsnode_install.sh && sync && /usr/local/app/tars/tarsnode_install.sh

# 配置crontab
echo "Starting crontab..."
grep -q -F "* * * * * root /usr/local/app/tars/tarsnode/util/monitor.sh" /etc/crontab || echo "* * * * * root /usr/local/app/tars/tarsnode/util/monitor.sh" >> /etc/crontab
crond

# 重新配置WEB管理端
echo "Reconfiguring WEB pages..."
mkdir -p /usr/local/resin/webapps/tars && cd /usr/local/resin/webapps/tars
jar -xvf ../tars.war

sed -i -r "s/tarsweb.datasource.tars.addr\s*=\s*.*/tarsweb.datasource.tars.addr=${TARS_DB_HOST}:${TARS_DB_PORT}/g" ./WEB-INF/classes/app.config.properties
sed -i -r "s/tarsweb.datasource.tars.user\s*=\s*.*/tarsweb.datasource.tars.user=${TARS_DB_USER}/g" ./WEB-INF/classes/app.config.properties
sed -i -r "s/tarsweb.datasource.tars.pswd\s*=\s*.*/tarsweb.datasource.tars.pswd=${TARS_DB_PASS}/g" ./WEB-INF/classes/app.config.properties
sed -i -r "s/locator\s*=\s*.*/locator=tars.tarsregistry.QueryObj@tcp -h ${TARS_REGISTRY_HOST} -p ${TARS_REGISTRY_PORT}/g" ./WEB-INF/classes/tars.conf

jar -uvf ../tars.war .
cd ~
rm -rf /usr/local/resin/webapps/tars

# 启动resin
echo "Starting resin..."
exec /usr/local/resin/bin/resin.sh console
