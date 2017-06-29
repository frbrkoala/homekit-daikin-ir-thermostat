# Usage: docker run -d --net=host --cap-add SYS_RAWIO --device /dev/mem:/dev/mem --device /dev/lirc0:/dev/lirc0 -v /local/path:/app/persist oznu/rpi-daikin-ir-controller

FROM resin/raspberry-pi-node:6.10

RUN apt-get update -y
RUN apt-get install -y lirc libnss-mdns avahi-discover libavahi-compat-libdnssd-dev

WORKDIR /tmp

# Install BCM2835 for DHT11 Sensor Support
RUN curl -SLO "http://www.airspayce.com/mikem/bcm2835/bcm2835-1.46.tar.gz" \
    && tar -zxvf bcm2835-1.46.tar.gz \
    && cd bcm2835-1.46 \
    && ./configure \
    && make \
    && make install \
    && rm -rf /tmp/*

# Add Module
RUN mkdir /app
WORKDIR /app

ADD package.json /app/
RUN npm install --production
RUN npm install node-dht-sensor

RUN echo "include \"/app/ac-ir-controller.conf\"" > /etc/lirc/lircd.conf
COPY init.d/hardware.conf /etc/lirc/hardware.conf
COPY init.d/avahi-daemon.conf /etc/avahi/avahi-daemon.conf
RUN mkdir -p /var/run/lirc && mkdir -p /var/run/dbus

ADD . /app/

EXPOSE 3003

RUN mkdir /init.d
COPY init.d/ /init.d
ENTRYPOINT ["/init.d/entrypoint.sh"]

CMD ["bin/www", "--dht"]