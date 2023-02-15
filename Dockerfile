# docker build --build-arg http_proxy=http://192.168.0.66:3128 --build-arg https_proxy=http://192.168.0.66:3128 .
FROM debian:bullseye-slim AS base

ENV LC_ALL C.UTF-8
ARG DEBIAN_FRONTEND=noninteractive
ARG http_proxy=""
ARG https_proxy=""


RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/force-unsafe-io && \
    apt-get -q update && \
    apt-get install -y eatmydata  && \
    eatmydata -- apt-get install -y apt-transport-https ca-certificates && \
    apt-get clean && rm -Rf /var/lib/apt/lists/*

COPY ./provisioning/sources.list /etc/apt/sources.list
COPY ./provisioning/debsury.gpg /etc/apt/trusted.gpg.d/debsury.gpg

RUN apt-get -qq update && \
    eatmydata -- apt-get -qy install \
        apache2 libapache2-mod-php8.0 \
        curl \
        git-core \
        netcat \
        jq \
        php8.0 php8.0-cli php8.0-curl php8.0-xml php8.0-mysql php8.0-mbstring php8.0-bcmath php8.0-zip php8.0-mysql php8.0-sqlite3 php8.0-opcache php8.0-xml php8.0-xsl php8.0-intl php8.0-xdebug php8.0-apcu php8.0-grpc php8.0-protobuf \
        zip unzip && \
    rm -Rf /var/lib/apt/lists/* && \
    a2enmod headers rewrite deflate php8.0 && \
    rm /etc/apache2/conf-enabled/other-vhosts-access-log.conf /etc/apache2/conf-enabled/serve-cgi-bin.conf && \
    update-alternatives --set php /usr/bin/php8.0

COPY ./provisioning/php.ini /etc/php/8.0/apache2/conf.d/local.ini
COPY ./provisioning/php.ini /etc/php/8.0/cli/conf.d/local.ini

RUN curl -so /usr/local/bin/composer https://getcomposer.org/download/2.5.2/composer.phar && chmod 755 /usr/local/bin/composer

RUN echo GMT > /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata \
    && mkdir -p "/var/log/apache2" \
    && ln -sfT /dev/stderr "/var/log/apache2/error.log" \
    && ln -sfT /dev/stdout "/var/log/apache2/access.log" 

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
EXPOSE 80
