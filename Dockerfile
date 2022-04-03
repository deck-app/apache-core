FROM alpine:edge AS builder
LABEL maintainer Naba Das <hello@get-deck.com>
ARG BUILD_DATE
ARG VCS_REF

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/deck-app/apache-stack.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.schema-version="2.0" \
      org.label-schema.vendor="PHP" \
      org.label-schema.name="docker-php" \
      org.label-schema.description="Docker For PHP Developers - Docker image with PHP 8.1.4, Apache, and Alpine" \
      org.label-schema.url="https://github.com/deck-app/apache-stack"

# PHP_INI_DIR to be symmetrical with official php docker image
ENV PHP_INI_DIR /etc/php81

# When using Composer, disable the warning about running commands as root/super user
ENV COMPOSER_ALLOW_SUPERUSER=1

# Persistent runtime dependencies
# Add repos
# RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing/x86_64/" >> /etc/apk/repositories

# Add basics first

ARG DEPS="\
        php81 \
        php81-phar \
        php81-bcmath \
        php81-calendar \
        php81-mbstring \
        php81-exif \
        php81-ftp \
        php81-openssl \
        php81-zip \
        php81-sysvsem \
        php81-sysvshm \
        php81-sysvmsg \
        php81-shmop \
        php81-sockets \
        php81-zlib \
        php81-bz2 \
        php81-curl \
        php81-simplexml \
        php81-xml \
        php81-opcache \
        php81-dom \
        php81-xmlreader \
        php81-xmlwriter \
        php81-tokenizer \
        php81-ctype \
        php81-session \
        php81-fileinfo \
        php81-iconv \
        php81-json \
        php81-posix \
        php81-apache2 \
        php81-pdo \
        php81-pdo_dblib \
        php81-pdo_mysql \
        php81-pdo_odbc \
        php81-pdo_pgsql\
        php81-pdo_sqlite \
        php81-mysqli \
        php81-mysqlnd \
        php81-dev \
        php81-pear \
        curl \
        ca-certificates \
        runit \
        apache2 \
        apache2-utils \
"

RUN set -x \
    && echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories \
    && apk add --no-cache $DEPS \
    && mkdir -p /run/apache2 \
    && ln -sf /dev/stdout /var/log/apache2/access.log \
    && ln -sf /dev/stderr /var/log/apache2/error.log

RUN apk add --no-cache openrc nano bash icu-libs

COPY apache/ /

COPY httpd.conf /etc/apache2/httpd.conf
ARG SERVER_ROOT

RUN sed -i "s#{SERVER_ROOT}#$SERVER_ROOT#g" /etc/apache2/httpd.conf

WORKDIR /var/www
COPY php_ini/php.ini /etc/php81/php.ini

ARG DISPLAY_PHPERROR
RUN if [ ${DISPLAY_PHPERROR} = true ]; then \
sed -i "s#{DISPLAY}#On#g" /etc/php8/php.ini \
;else \
sed -i "s#{DISPLAY}#Off#g" /etc/php8/php.ini \
;fi

RUN mv /usr/bin/php8 /usr/bin/php
RUN apk add --no-cache openssl openssl-dev curl openrc nano bash icu-libs p7zip gdbm libsasl snappy gcc make g++ zlib-dev php81-zip zip unzip icu-dev php81-pecl-mongodb php81-intl git

RUN ln -s /usr/bin/php81 /usr/bin/php
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer
RUN apk update
RUN apk upgrade
FROM scratch
COPY --from=builder / /
WORKDIR /var/www
RUN chmod +x /etc/service/apache/run
RUN chmod +x /sbin/runit-wrapper
RUN chmod +x /sbin/runsvdir-start

EXPOSE 80

CMD ["/sbin/runit-wrapper"]