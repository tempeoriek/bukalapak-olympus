FROM surnet/alpine-wkhtmltopdf:3.10-0.12.5-full as wkhtmltopdf

FROM asia.gcr.io/cloudeng-prod-cicd/infra/docker/base-images/ruby:2.6.5-alpine3.10

RUN apk add --update --no-cache --virtual build_deps \
    build-base ruby-dev libc-dev linux-headers git \
    mysql-dev less libsodium-dev

RUN apk add --update --no-cache --wait 10 libstdc++ libx11 libxrender \
    libxext ca-certificates fontconfig freetype ttf-dejavu \
    ttf-droid ttf-freefont ttf-liberation ttf-ubuntu-font-family

# Set your workdir
WORKDIR /app

ARG CI_JOB_TOKEN
RUN git config --global url."https://gitlab-ci-token:${CI_JOB_TOKEN}@runner.gitlab.cloud.bukalapak.io/".insteadOf "git@git.gitlab.cloud.bukalapak.io:"

# Install all the dependency
COPY Gemfile Gemfile.lock ./

RUN CFLAGS="-Wno-cast-function-type" \
      BUNDLE_FORCE_RUBY_PLATFORM=true \
      bundle install -j4 --without development test

COPY --from=wkhtmltopdf /bin/wkhtmltoimage /usr/local/bundle/gems/wkhtmltoimage-binary-0.12.5/libexec/wkhtmltoimage-amd64
COPY --from=wkhtmltopdf /bin/wkhtmltopdf /usr/local/bundle/gems/wkhtmltopdf-binary-edge-0.12.5.1/libexec/wkhtmltopdf-linux-amd64
