FROM 9chu/tars-node
MAINTAINER 1871361697@qq.com

WORKDIR /root/
VOLUME ["/data"]

# 暴露端口
EXPOSE 873
EXPOSE 8080
EXPOSE 10000
EXPOSE 10001
#EXPOSE 12000
EXPOSE 17890
EXPOSE 17891
EXPOSE 19385

# 启动参数
ENV TARS_BIND_INTERFACE eth0
ENV TARS_DB_HOST db.tars.com
ENV TARS_DB_PORT 3306
ENV TARS_DB_USER tars
ENV TARS_DB_PASS tars2015
ENV OPENVPN_ENABLE 0
ENV OPENVPN_CONFIG /data/node.ovpn
ENV OPENVPN_LOG /data/log/openvpn.log

# 创建入口
COPY entrypoint.sh /root/entrypoint.sh
RUN chmod +x /root/entrypoint.sh
ENTRYPOINT [ "/usr/local/sbin/pid1" ]
CMD bash -c "/root/entrypoint.sh"
