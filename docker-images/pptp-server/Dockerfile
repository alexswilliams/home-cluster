FROM alpine:3.9.4
RUN apk update && \
    apk upgrade && \
    apk --no-cache add pptpd ppp && \
    rm -rf /var/cache/apk/* && \
    mv -f /etc/pptpd.conf /etc/pptpd.conf.bak && \
    mv -f /etc/ppp/chap-secrets /etc/ppp/chap-secrets.bak
EXPOSE 1723/tcp
CMD pptpd && syslogd -n -O /dev/stdout
