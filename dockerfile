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

