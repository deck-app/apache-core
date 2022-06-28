FROM alpine:3.12 AS builder
LABEL maintainer Naba Das <hello@get-deck.com>
# Add basics first
RUN export DOCKER_BUILDKIT=1
ARG DEPS="\
        php7 \
        php7-phar \
        php7-bcmath \
        php7-calendar \
        php7-mbstring \
        php7-exif \
        php7-ftp \
        php7-openssl \
        php7-zip \
        php7-sysvsem \
        php7-sysvshm \
        php7-sysvmsg \
        php7-shmop \
        php7-sockets \
        php7-zlib \
        php7-bz2 \
        php7-curl \
        php7-simplexml \
        php7-xml \
        php7-opcache \
        php7-dom \
        php7-xmlreader \
        php7-xmlwriter \
        php7-tokenizer \
        php7-ctype \
        php7-session \
        php7-fileinfo \
        php7-iconv \
        php7-json \
        php7-posix \
        php7-apache2 \
        php7-pdo \
        php7-pdo_dblib \
        php7-pdo_mysql \
        php7-pdo_odbc \
        php7-pdo_pgsql\
        php7-pdo_sqlite \
        php7-mysqli \
        php7-mysqlnd \
        php7-dev \
        php7-pear \
        curl \
        ca-certificates \
        runit \
        apache2 \
        git \
        apache2-utils \
	snappy \
        bash \
"

RUN set -x \
    && apk add --no-cache $DEPS \
    && mkdir -p /run/apache2 \
    && ln -sf /dev/stdout /var/log/apache2/access.log \
    && ln -sf /dev/stderr /var/log/apache2/error.log

RUN apk --update add --no-cache  openrc nano bash icu-libs openssl openssl-dev gcc make g++ zlib-dev gdbm libsasl snappy
RUN apk upgrade
COPY apache/ /
COPY httpd.conf /etc/apache2/httpd.conf
COPY php_ini/php.ini /etc/php7/
WORKDIR /var/www

# RUN ln -s /usr/bin/php7 /usr/bin/php
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer 
RUN ln -s /etc/php7 /etc/php
# RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories
# RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/main/" >> /etc/apk/repositories
RUN apk add icu-libs icu-dev python3 python2 curl git --virtual .php-deps --virtual .build-deps $PHPIZE_DEPS zlib-dev icu-dev
RUN apk add php7-intl
RUN pecl install mongodb

FROM scratch
COPY --from=builder / /
WORKDIR /var/www
RUN chmod +x /etc/service/apache/run
RUN chmod +x /sbin/runit-wrapper
RUN chmod +x /sbin/runsvdir-start

EXPOSE 80

CMD ["/sbin/runit-wrapper"]
