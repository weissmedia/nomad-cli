FROM docker:latest 

MAINTAINER Mathias Weiß <mathias.weiss@power.cloud>

ENV GLIBC_VERSION "2.32-r0"

RUN set -x \
 # per https://github.com/hashicorp/nomad/issues/5535#issuecomment-651888183
 && export -n LD_BIND_NOW \
 # per https://github.com/sgerrand/alpine-pkg-glibc/issues/51#issuecomment-302530493
 && apk del libc6-compat \
 && apk --update add --no-cache --virtual tzdata dpkg curl ca-certificates gnupg libcap openssl dumb-init \
 && curl -Ls https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk > /tmp/glibc-${GLIBC_VERSION}.apk \
 && apk add --allow-untrusted --no-cache /tmp/glibc-${GLIBC_VERSION}.apk \
 && rm -rf /tmp/glibc-${GLIBC_VERSION}.apk /var/cache/apk/* \
 && apk del gnupg openssl

ARG nomad_version
ARG architecture
ENV NOMAD_VERSION $nomad_version
ENV ARCHITECTURE $architecture

ADD https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_${ARCHITECTURE}.zip /tmp/nomad.zip
RUN cd /bin \
  && unzip /tmp/nomad.zip \
  && chmod +x /bin/nomad \
  && rm /tmp/nomad.zip \
  && nomad version
