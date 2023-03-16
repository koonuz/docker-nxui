FROM alpine:latest
COPY x-ui.sh /usr/local/x-ui.sh
ENV GET_VERSION 0.3.4.0
ENV GET_ARCH amd64
RUN apk update && \
    apk add --no-cache tzdata wget tar runit curl socat && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2 && \
    cd /usr/local && \
    wget -q https://github.com/FranzKafkaYu/x-ui/releases/download/${GET_VERSION}/x-ui-linux-${GET_ARCH}.tar.gz && \
    tar -zxvf x-ui-linux-${GET_ARCH}.tar.gz && \
    rm x-ui-linux-${GET_ARCH}.tar.gz && \
    mv x-ui.sh x-ui/x-ui.sh && \
    chmod +x x-ui/x-ui x-ui/bin/xray-linux-${GET_ARCH} x-ui/x-ui.sh && \
    rm -rf /var/cache/apk/*

COPY runit /etc/service
RUN chmod +x /etc/service/xui/run
WORKDIR /usr/local/x-ui
CMD [ "runsvdir", "-P", "/etc/service"]
