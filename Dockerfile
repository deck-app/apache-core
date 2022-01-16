FROM alpine
LABEL maintainer Naba Das <hello@get-deck.com>
ARG BUILD_DATE
ARG VCS_REF

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/deck-app/apache-stack.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.schema-version="2.0" \
      org.label-schema.vendor="PHP" \
      org.label-schema.name="docker-php" \
      org.label-schema.description="Docker For PHP Developers - Docker image with PHP 8.0.11, Apache, and Alpine" \
      org.label-schema.url="https://github.com/deck-app/apache-stack"

# PHP_INI_DIR to be symmetrical with official php docker image
ENV PHP_INI_DIR /etc/php8

# When using Composer, disable the warning about running commands as root/super user
ENV COMPOSER_ALLOW_SUPERUSER=1

# Persistent runtime dependencies
# Add repos
# RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing/x86_64/" >> /etc/apk/repositories

# Add basics first

ARG DEPS="\
        php8 \
        php8-phar \
        php8-bcmath \
        php8-calendar \
        php8-mbstring \
        php8-exif \
        php8-ftp \
        composer \
        php8-openssl \
        php8-zip \
        php8-sysvsem \
        php8-sysvshm \
        php8-sysvmsg \
        php8-shmop \
        php8-sockets \
        php8-zlib \
        php8-bz2 \
        php8-curl \
        php8-simplexml \
        php8-xml \
        php8-opcache \
        php8-dom \
        php8-xmlreader \
        php8-xmlwriter \
        php8-tokenizer \
        php8-ctype \
        php8-session \
        php8-fileinfo \
        php8-iconv \
        php8-json \
        php8-posix \
        php8-apache2 \
        php8-pdo \
        php8-pdo_dblib \
        php8-pdo_mysql \
        php8-pdo_odbc \
        php8-pdo_pgsql\
        php8-pdo_sqlite \
        php8-mysqli \
        php8-mysqlnd \
        php8-dev \
        php8-pear \
        curl \
        ca-certificates \
        runit \
        apache2 \
        apache2-utils \
"

RUN set -x \
    # && echo "http://dl-cdn.alpinelinux.org/alpine/edge/community/x86_64/" >> /etc/apk/repositories \
    && apk add --no-cache $DEPS \
    && mkdir -p /run/apache2 \
    && ln -sf /dev/stdout /var/log/apache2/access.log \
    && ln -sf /dev/stderr /var/log/apache2/error.log

RUN apk add openrc
RUN apk add nano
RUN apk add bash
RUN apk add icu-libs

COPY apache/ /

COPY httpd.conf /etc/apache2/httpd.conf
ARG SERVER_ROOT

RUN sed -i "s#{SERVER_ROOT}#$SERVER_ROOT#g" /etc/apache2/httpd.conf

VOLUME [ "/var/www/" ]
WORKDIR /var/www
COPY php_ini/php.ini /etc/php/8.0/php.ini
RUN rm -rf /etc/apache2/conf.d/php7-module.conf
COPY php8-module.conf /etc/apache2/conf.d/php8-module.conf

ARG DISPLAY_PHPERROR
RUN if [ ${DISPLAY_PHPERROR} = true ]; then \
sed -i "s#{DISPLAY}#On#g" /etc/php8/php.ini \
;else \
sed -i "s#{DISPLAY}#Off#g" /etc/php8/php.ini \
;fi

RUN mv /usr/bin/php8 /usr/bin/php
RUN apk add --no-cache openssl openssl-dev
RUN apk add curl
RUN apk --update add gcc make g++ zlib-dev
RUN apk --update add --no-cache gdbm libsasl snappy
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/main/" >> /etc/apk/repositories
RUN apk add --no-cache php8-pecl-mongodb
RUN apk add php8-intl
RUN ln -s /usr/bin/php /usr/bin/php8
RUN apk update
RUN apk upgrade

RUN chmod +x /etc/service/apache/run
RUN chmod +x /sbin/runit-wrapper
RUN chmod +x /sbin/runsvdir-start

EXPOSE 80

CMD ["/sbin/runit-wrapper"]