# Dockerfile.rails
FROM ruby:2.6.5

RUN apt-get -y update && \
    apt-get -y install libsodium-dev

# Default directory
ENV INSTALL_PATH /opt/app
RUN mkdir -p $INSTALL_PATH
WORKDIR $INSTALL_PATH

# Install rails
COPY Gemfile Gemfile.lock ./

# Add GitLabs's SSH host keys to the known hosts and install your dependencies
RUN gem install bundler
RUN --mount=type=ssh mkdir -p -m 0600 ~/.ssh && \
    ssh-keyscan git.gitlab.cloud.bukalapak.io >> ~/.ssh/known_hosts && \
    bundler
