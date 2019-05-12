FROM fluent/fluentd:v1.4.2-debian-2.0

# Use root account to use apt
USER root

RUN buildDeps="sudo make gcc g++ libc-dev ruby-dev" \
    && apt-get update \
    && apt-get install -y --no-install-recommends $buildDeps \
    && sudo gem install fluent-plugin-prometheus --version="~>1.0.0" \
    && sudo gem sources --clear-all \
    && SUDO_FORCE_REMOVE=yes \
    apt-get purge -y --auto-remove \
                  -o APT::AutoRemove::RecommendsImportant=false \
                  $buildDeps \
    && rm -rf /var/lib/apt/lists/* \
              /home/fluent/.gem/ruby/2.3.0/cache/*.gem

USER fluent
