FROM bitwalker/alpine-erlang:19.3

RUN apk update && \
    apk --no-cache --update add libgcc libstdc++ && \
    rm -rf /var/cache/apk/*

EXPOSE 4000
ENV PORT=4000 MIX_ENV=prod REPLACE_OS_VARS=true SHELL=/bin/sh

ADD ${APP}.tar.gz ./
RUN chown -R default ./releases

USER default

ENTRYPOINT ["/opt/app/bin/${APP}"]
