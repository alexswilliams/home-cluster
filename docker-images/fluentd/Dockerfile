FROM fluent/fluentd:v1.8.1-debian-1.0

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="FluentD with Prometheus Plugin" \
      org.label-schema.description="FluentD with the prometheus plugin pre-bundled" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/alexswilliams/home-cluster" \
      org.label-schema.schema-version="1.0"


# Use root account to use apt
USER root

RUN buildDeps="sudo make gcc g++ libc-dev ruby-dev" \
    && apt-get update \
    && apt-get install -y --no-install-recommends $buildDeps \
    && sudo gem install fluent-plugin-prometheus --version="~>1.6.0" \
    && sudo gem sources --clear-all \
    && SUDO_FORCE_REMOVE=yes \
    apt-get purge -y --auto-remove \
                  -o APT::AutoRemove::RecommendsImportant=false \
                  $buildDeps \
    && rm -rf /var/lib/apt/lists/* \
              /home/fluent/.gem/ruby/2.*/cache/*.gem

USER fluent
