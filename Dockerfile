FROM ubuntu:20.04

LABEL maintainer="Thomas Bruckmann <thomas.bruckmann@posteo.de>"

RUN    apt update \
    && apt -y upgrade \
    && apt -y install apt-utils \
    && apt -y install \
        clamav-base\
        clamav \
        clamav-daemon \
        clamav-freshclam \
        libclamunrar9 \
        ca-certificates \
        netcat-openbsd \
        wget \
        rsync \
        dnsutils \
        cron \
        sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install unofficial signatures
RUN mkdir -p /usr/local/sbin/ \
    && wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/clamav-unofficial-sigs.sh -O /usr/local/sbin/clamav-unofficial-sigs.sh \
    && chmod 755 /usr/local/sbin/clamav-unofficial-sigs.sh \
    && mkdir -p /etc/clamav-unofficial-sigs/ \
    && wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/master.conf -O /etc/clamav-unofficial-sigs/master.conf \
    && wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/user.conf -O /etc/clamav-unofficial-sigs/user.conf \
    && wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/os/os.ubuntu.conf -O /etc/clamav-unofficial-sigs/os.conf \
    && /usr/local/sbin/clamav-unofficial-sigs.sh --force \
    && /usr/local/sbin/clamav-unofficial-sigs.sh --install-logrotate \
    && /usr/local/sbin/clamav-unofficial-sigs.sh --install-cron

# initial update of av databases
RUN wget -O /var/lib/clamav/main.cvd http://database.clamav.net/main.cvd && \
    wget -O /var/lib/clamav/daily.cvd http://database.clamav.net/daily.cvd && \
    wget -O /var/lib/clamav/bytecode.cvd http://database.clamav.net/bytecode.cvd && \
    chown clamav:clamav /var/lib/clamav/*.cvd

# permission juggling
RUN mkdir -p /var/run/clamav && \
    chown clamav:clamav /var/run/clamav && \
    chmod 750 /var/run/clamav

# av configuration update
RUN sed -i 's/^Foreground .*$/Foreground true/g' /etc/clamav/clamd.conf && \
    echo "TCPSocket 3310" >> /etc/clamav/clamd.conf && \
    if [ -n "$HTTPProxyServer" ]; then echo "HTTPProxyServer $HTTPProxyServer" >> /etc/clamav/freshclam.conf; fi && \
    if [ -n "$HTTPProxyPort"   ]; then echo "HTTPProxyPort $HTTPProxyPort" >> /etc/clamav/freshclam.conf; fi && \
    if [ -n "$DatabaseMirror"  ]; then echo "DatabaseMirror $DatabaseMirror" >> /etc/clamav/freshclam.conf; fi && \
    if [ -n "$DatabaseMirror"  ]; then echo "ScriptedUpdates off" >> /etc/clamav/freshclam.conf; fi && \
    sed -i 's/^Foreground .*$/Foreground true/g' /etc/clamav/freshclam.conf


# env based configs - will be called by bootstrap.sh
COPY envconfig.sh /
COPY check.sh /
COPY bootstrap.sh /
COPY clamav /etc/sudoers.d/clamav

# port provision
EXPOSE 3310

RUN chown clamav:clamav bootstrap.sh check.sh envconfig.sh /etc/clamav /etc/clamav/clamd.conf /etc/clamav/freshclam.conf && \
    chmod u+x bootstrap.sh check.sh envconfig.sh

USER clamav

CMD ["/bootstrap.sh"]
