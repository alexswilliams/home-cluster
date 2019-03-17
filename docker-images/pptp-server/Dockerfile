FROM alpine:3.9.2
RUN apk --no-cache add pptpd ppp --update && \
    rm -rf /var/cache/apk/* && \
    mv -f /etc/pptpd.conf /etc/pptpd.conf.bak && \
    mv -f /etc/ppp/chap-secrets /etc/ppp/chap-secrets.bak
EXPOSE 1723/tcp
CMD pptpd && syslogd -n -O /dev/stdout
