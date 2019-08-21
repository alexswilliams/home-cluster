FROM alpine:3.10.2

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="PPTP Server" \
      org.label-schema.description="Alpine-based PPTP server" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/alexswilliams/home-cluster" \
      org.label-schema.schema-version="1.0"

RUN apk update && \
    apk upgrade && \
    apk --no-cache add pptpd ppp && \
    rm -rf /var/cache/apk/* && \
    mv -f /etc/pptpd.conf /etc/pptpd.conf.bak && \
    mv -f /etc/ppp/chap-secrets /etc/ppp/chap-secrets.bak
EXPOSE 1723/tcp
CMD pptpd && syslogd -n -O /dev/stdout
