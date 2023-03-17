FROM alpine:latest
COPY runit /etc/service
COPY x-ui.sh /root/x-ui.sh
ENV GET_VERSION 0.3.4.0
ENV GET_ARCH amd64
RUN apk update && \
    apk add --no-cache tzdata runit bash && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2 && \
    wget --no-check-certificate -P /root https://github.com/FranzKafkaYu/x-ui/releases/download/${GET_VERSION}/x-ui-linux-${GET_ARCH}.tar.gz && \
    tar -zxvf /root/x-ui-linux-${GET_ARCH}.tar.gz -C /root && \
    rm /root/x-ui-linux-${GET_ARCH}.tar.gz && \
    mv /root/x-ui /root/xui && \
    mv /root/xui/* /root && \
    chmod +x /root /etc/service/xui/run && \
    chown -R root:root /root && \
    rm -rf /var/cache/apk/* /root/xui

WORKDIR /root
CMD ["runsvdir", "-P", "/etc/service"]
