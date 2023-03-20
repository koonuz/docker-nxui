FROM alpine:latest
COPY runit /etc/service
COPY x-ui.sh /usr/local/x-ui.sh
ENV GET_VERSION 0.3.4.0
ENV GET_ARCH amd64
RUN apk update && \
    apk add --no-cache tzdata runit bash && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2 && \
    wget --no-check-certificate -P /usr/local https://github.com/FranzKafkaYu/x-ui/releases/download/${GET_VERSION}/x-ui-linux-${GET_ARCH}.tar.gz && \
    tar -zxvf /usr/local/x-ui-linux-${GET_ARCH}.tar.gz -C /usr/local && \
    rm /usr/local/x-ui-linux-${GET_ARCH}.tar.gz /usr/local/x-ui/x-ui.service && \
    mv /usr/local/x-ui.sh /usr/local/x-ui/x-ui.sh && \
    chmod +x /usr/local/x-ui/* /etc/service/xui/run && \
    rm -rf /var/cache/apk/*

WORKDIR /usr/local/x-ui
CMD ["runsvdir", "-P", "/etc/service"]
