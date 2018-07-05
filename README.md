# tars-center

该仓库为腾讯[Tars微服务框架](https://github.com/Tencent/Tars)的中心节点容器。

此节点容器作为微服务执行的中心管理节点，已包含了最基本的框架支撑服务和WEB管理页面，基于CentOS镜像构建而成。

## 安装顺序

### 创建数据库用户并赋予权限

```sql
CREATE USER tars IDENTIFIED BY 'tars2015';
GRANT ALL PRIVILEGES ON db_tars.* TO tars;
GRANT ALL PRIVILEGES ON tars_property.* TO tars;
GRANT ALL PRIVILEGES ON tars_stat.* TO tars;
FLUSH PRIVILEGES;
```

数据库使用`mysql 5.6`。

### 启动DOCKER

```shell
docker run -v /Users/chu/Docker/node-center:/data -e TARS_DB_HOST=db.example.com -d --name node-center 9chu/tars-center
```

### 从管理端手动安装组件

请参考TARS安装手册。

相关的安装包会被自动拷贝到`/data/install`下。

## 基本参数

- TARS\_BIND_INTERFACE

    指定各个服务绑定的网卡。默认为eth0。

- TARS\_DB_HOST

    指定数据库主机名，默认为db.tars.com，必须填写。

- TARS\_DB_PORT

    指定数据库的端口，默认为3306。

- TARS\_DB_USER

    指定数据库的用户名，默认为tars。

- TARS\_DB_PASSWD

    指定数据库的密码，默认为tars2015。

- OPENVPN_ENABLE

    是否启用OpenVPN，用于组建跨机器部署的环境。默认为0。

- OPENVPN_CONFIG

    指定OpenVPN客户端配置文件。默认为/data/node.ovpn。

- OPENVPN_LOG

    指定OpenVPN的日志文件路径。默认为/data/log/openvpn.log。

## 挂载目录

- /data

    容器需要挂载/data目录作为数据目录，如此一来即便重建容器也能恢复其运行的状态。

    在数据目录下将会看到下述子目录。

        /data/log：日志目录
        /data/tars：TARS基础组件数据目录。
        /data/patch：补丁目录。
        /data/node：连接到tarsnode/data，亦为其他服务的部署目录。
        /data/install：基础组件包目录。

## 暴露端口

- 873

    rsync端口。

- 8080

    WEB管理端端口。

- 10000

    补丁发布服务端口。

- 10001

    配置文件服务端口。

- 17890

    注册表端口，用于节点和服务发现。

- 17891

    注册表端口，用于节点和服务注册。

- 19385

    节点端口，当前容器的节点对外暴露的服务端口。

## 参考

- https://github.com/tangramor/tars-master
