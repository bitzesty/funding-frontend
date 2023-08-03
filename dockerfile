ARG RUBY_VERSION=3.1.1

FROM ruby:$RUBY_VERSION

# Set Docker's working directory
WORKDIR /docker/app

# Install fundamentals, git, npm, node and yarn
# This builds with a node v16.20.1 binary, so dev env needs to match that
RUN apt-get update -qq && apt-get install -y build-essential apt-utils libpq-dev git \
    -y curl gnupg2 && \
    curl -sL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn

# Copy these 2 files to working directory, check the
# dependencies and node versions sync, and generate node_modules.
COPY package.json ./
COPY yarn.lock ./
RUN yarn install --check-files

# Install same bundler as developing with
RUN gem install bundler -v 2.3.11

# Copy generated lock to Docker's working directory and install
COPY Gemfile Gemfile.lock ./
RUN bundle install

ADD . /docker/app

# The username must have a matching user on the database.
# The username must be set by a build argument
# Group will have same name as username.  Home directory for user created.
ARG RAILS_RUNNING_USER
RUN useradd --user-group --system --create-home -u 1001 --no-log-init $RAILS_RUNNING_USER

# New user owns /docker/app
RUN chown -R $RAILS_RUNNING_USER:$RAILS_RUNNING_USER /docker/app
# /docker/app can be read, written and executed from by new user
RUN chmod 700 /docker/app

# Switch to user created above
USER $RAILS_RUNNING_USER

# Exposes port for other containers and docker desktop
EXPOSE 3000

# run rails server -b 0.0.0.0 -p 3000
ENTRYPOINT ["rails","server", "-b", "0.0.0.0", "-p", "3000"]


# https://www.mend.io/free-developer-tools/blog/docker-expose-port/
# EXPOSE makes the stated ports available for inter-container interaction.
# EXPOSE is a documentation mechanism that gives configuration information
# another command can use, provides a hint about which initial incoming ports
# will provide services.
# EXPOSE instruction does not expose the container’s ports to be accessible from the host.
# ARG DEFAULT_PORT 3000
# EXPOSE ${DEFAULT_PORT}

# Install fundamentals, git,
# RUN apt-get update -qq && apt-get install -y build-essential apt-utils libpq-dev git

# Bash stuff execeutes, but runs in a new interactive session.
# Need to get NPM on /bin/sh -c path for this method to work
# Then we can pick any node version we want using npm
# This means the files aren't going where you want.  
# For instance, if you delete the yarn lock - a new one isn't built.
# RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
# RUN nvm install -g 16.14.2 |bash
# # These lines check that node and npm are on the path
# RUN node -v
# RUN npm -v
# RUN echo "export PATH=/new/path:${PATH}" >> /root/.bashrc
# RUN npm install -g yarn
# RUN yarn install --check-files

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
# Or # CMD [ "bundle","exec", "puma", "config.ru"] 
