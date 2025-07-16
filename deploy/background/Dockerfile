ARG BASE_IMAGE
ARG BASE_VERSION

FROM ${BASE_IMAGE}:${BASE_VERSION}

# Add service
COPY . /app

ENV RAILS_ENV production

# Expose your service port
EXPOSE 8087

# Add all bin to PATH
ENV PATH "$PATH:/app/bin"

# Set your entrypoint here just to start the webserver such as puma
ENTRYPOINT ["bundle", "exec", "/app/bin/background"]
