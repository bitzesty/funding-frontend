ARG RUBY_VERSION=3.1.1

FROM ruby:$RUBY_VERSION

RUN apt-get update -qq && apt-get install -y build-essential apt-utils libpq-dev nodejs yarn git

WORKDIR /docker/app

RUN gem install bundler

COPY Gemfile* ./

RUN bundle install

COPY yarn.lock ./

# RUN yarn install --check-files 

ADD . /docker/app

ARG DEFAULT_PORT 3000

EXPOSE ${DEFAULT_PORT}

CMD [ "bundle","exec", "puma", "config.ru"] # CMD ["rails","server"] # you can also write like this.


# ARG RUBY_VERSION=3.2.0
# FROM ruby:$RUBY_VERSION
# # Install libvips for Active Storage preview support
# RUN apt-get update -qq && \
#     apt-get install -y build-essential libvips bash bash-completion libffi-dev tzdata postgresql nodejs npm yarn && \
#     apt-get clean && \
#     rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man
 
# # Rails app lives here
# WORKDIR /rails
# # Set production environment
# ENV RAILS_LOG_TO_STDOUT="1" \
#     RAILS_SERVE_STATIC_FILES="true" \
#     RAILS_ENV="production" \
#     BUNDLE_WITHOUT="development"
# # Install application gems
# COPY Gemfile Gemfile.lock ./
# RUN bundle install
# # Copy application code
# COPY . .
# # Precompile bootsnap code for faster boot times
# RUN bundle exec bootsnap precompile --gemfile app/ lib/
# # Precompiling assets for production without requiring secret RAILS_MASTER_KEY
# RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile
# # Entrypoint prepares the database.
# ENTRYPOINT ["/rails/bin/docker-entrypoint"]
# # Start the server by default, this can be overwritten at runtime
# EXPOSE 3000
# CMD ["./bin/rails", "server"]''