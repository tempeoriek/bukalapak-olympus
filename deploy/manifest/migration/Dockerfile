FROM asia.gcr.io/cloudeng-prod-cicd/sre/migration:1.1.3

COPY db /app/db
RUN gem install makara
ENV RAILS_ENV production
