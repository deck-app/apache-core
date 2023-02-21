FROM alpine:latest AS builder
LABEL maintainer Naba Das <hello@get-deck.com>
# Add basics first
RUN export DOCKER_BUILDKIT=1
ARG DEPS="\
        php82 \
        php82-phar \
        php82-bcmath \
        php82-calendar \
        php82-mbstring \
        php82-exif \
        php82-ftp \
        # composer \
        php82-openssl \
        php82-zip \
        php82-sysvsem \
        php82-sysvshm \
        php82-sysvmsg \
        php82-shmop \
        php82-sockets \
        php82-zlib \
        php82-bz2 \
        php82-curl \
        php82-simplexml \
        php82-xml \
        php82-opcache \
        php82-dom \
        php82-xmlreader \
        php82-xmlwriter \
        php82-tokenizer \
        php82-ctype \
        php82-session \
        php82-fileinfo \
        php82-iconv \
        php82-json \
        php82-posix \
        php82-apache2 \
        php82-pdo \
        php82-pdo_dblib \
        php82-pdo_mysql \
        php82-pdo_odbc \
        php82-pdo_pgsql\
        php82-pdo_sqlite \
        php82-mysqli \
        php82-mysqlnd \
        php82-dev \
        php82-pear \
        curl \
        ca-certificates \
        runit \
	git \
        apache2 \
        apache2-utils \
	php82-intl \
	snappy \
        bash \
"

RUN set -x \
    && echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
    && apk add --no-cache $DEPS \
    && mkdir -p /run/apache2 \
    && ln -sf /dev/stdout /var/log/apache2/access.log \
    && ln -sf /dev/stderr /var/log/apache2/error.log

# RUN apk --update add --no-cache  openrc nano bash icu-libs openssl openssl-dev gcc make g++ zlib-dev gdbm libsasl snappy php82-intl
# RUN ln -s /usr/bin/php82 /usr/bin/php
# RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer
RUN apk upgrade

COPY apache/ /
COPY httpd.conf /etc/apache2/httpd.conf
ARG SERVER_ROOT
RUN sed -i "s#{SERVER_ROOT}#$SERVER_ROOT#g" /etc/apache2/httpd.conf
COPY php_ini/php.ini /etc/php82/
WORKDIR /var/www
RUN apk add curl nodejs npm
RUN ln -s /usr/bin/php82 /usr/bin/php
RUN ln -s /etc/php82 /etc/php
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/main/" >> /etc/apk/repositories
RUN apk add --no-cache php82-pecl-mongodb
FROM scratch
COPY --from=builder / /
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer
RUN apk upgrade
WORKDIR /var/www
RUN chmod +x /etc/service/apache/run
RUN chmod +x /sbin/runit-wrapper
RUN chmod +x /sbin/runsvdir-start

EXPOSE 80

CMD ["/sbin/runit-wrapper"]
