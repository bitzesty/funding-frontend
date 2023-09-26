# syntax=docker/dockerfile:1

FROM phusion/passenger-ruby31:latest

ENV HOME /home/app/deploy

# Install common dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  --mount=type=tmpfs,target=/var/log \
  apt-get update -qq \
  && apt-get dist-upgrade -y \
  && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
  curl \
  gnupg2 \
  less \
  tzdata \
  time \
  locales \
  && update-locale LANG=C.UTF-8 LC_ALL=C.UTF-8

# Install NodeJS and Yarn
ARG NODE_MAJOR=16
RUN yes | apt remove nodejs
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  --mount=type=tmpfs,target=/var/log \
  apt-get update && \
  apt-get install -y curl software-properties-common && \
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
  echo "deb https://deb.nodesource.com/node_${NODE_MAJOR}.x $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/nodesource.list && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends nodejs

ARG YARN_VERSION=latest
RUN npm install -g yarn@$YARN_VERSION

# Configure bundler
ENV RAILS_ENV=production \
  NODE_ENV=production \
  BUNDLE_JOBS=4 \
  BUNDLE_RETRY=3 \
  BUNDLE_APP_CONFIG=/home/app/.bundle \
  BUNDLE_PATH=/home/app/.bundle \
  GEM_HOME=/home/app/.bundle \
  PATH="$HOME/bin:${PATH}" \
  LANG=C.UTF-8 \
  LC_ALL=C.UTF-8


# Upgrade RubyGems and install the latest Bundler version
ARG BUNDLER_VERSION=2.3.11
RUN echo "gem: --no-rdoc --no-ri >> \"$HOME/.gemrc\""
RUN gem update --system && \
  gem install bundler:$BUNDLER_VERSION

# Create a directory for the app code
RUN mkdir -p $HOME
WORKDIR $HOME

# Install Ruby gems
COPY --chown=app:app Gemfile Gemfile.lock ./
RUN bundle lock --add-platform aarch64-linux

RUN mkdir $BUNDLE_PATH \
  && bundle config --local path "${BUNDLE_PATH}" \
  && bundle config --local without 'development test' \
  && bundle config --local clean 'true' \
  && bundle config --local no-cache 'true' \
  && bundle install --jobs=${BUNDLE_JOBS} \
  && rm -rf $BUNDLE_PATH/ruby/3.1.0/cache/* \
  && rm -rf $HOME/.bundle/cache/*

# Install JS packages
COPY --chown=app:app package.json yarn.lock ./
RUN yarn install --check-files

RUN mkdir -p $HOME/tmp/pids

COPY --chown=app:app . .

# Precompile assets

RUN SKIP_SALESFORCE_INIT=true SKIP_FLIPPER_INIT=true SECRET_KEY_BASE=dummyvalue bundle exec rake assets:precompile

RUN mkdir -p /etc/my_init.d
COPY docker/puma.sh /etc/my_init.d/puma.sh
COPY docker/workers.sh /etc/my_init.d/workers.sh


CMD ["/sbin/my_init"]
EXPOSE 3000
