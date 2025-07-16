![Coverage Status](https://gitlab.cloud.bukalapak.io/bukalapak/olympus/badges/master/coverage.svg?job=test)
![pipeline](https://gitlab.cloud.bukalapak.io/bukalapak/olympus/badges/master/pipeline.svg)

# Olympus

## Description

Olympus is a Virtual Product Postpaid System. Designed for supporting Mothership interaction with 3rd party virtual product postpaid system. Features that currently supported by Olympus are:
- Electricity Postpaid (**Listrik PLN Pascabayar**)
- National Health Insurance (**BPJS Kesehatan**)
- Water Bill (**Tagihan PDAM**)
- Phone Credit Postpaid (**Pulsa Pascabayar**)
- Credit Card Bill (**Tagihan Kartu Kredit**)

## SLO and SLI

- Availability: 99.9%
- Error Rate: < 5%
- Mean Response Time: < 10s

## Architecture Diagram

[Diagram](https://bukalapak.atlassian.net/wiki/spaces/O2OVPD/pages/2503681561/Electricity+Postpaid+Customer+Inquiry+and+Payment#Architecture-Diagram)

## Contact and On-Call Information

- [#o2o-vp-support](https://bukalapak.slack.com/archives/CTPEZ3FFF) (Slack support channel)
* [Faris Arifiansyah](https://bukalapak.slack.com/team/UCACY64BX)
* [Kristoporus Nathan Wilianto](https://bukalapak.slack.com/team/U040TFSB47L)
* [Arif Bintoro](https://bukalapak.slack.com/team/U01SPFTN3Q8)
* [Galuh Buana Putra Kautsar](https://bukalapak.slack.com/team/US0L3KS1H)
* [Alex Tan Hong Pin](https://bukalapak.slack.com/team/U04U09QEAPJ)
* [Jonathan Jusuf](https://bukalapak.slack.com/team/U01JKR8HQP2)

## Links

- [Confluence](https://bukalapak.atlassian.net/wiki/spaces/VP/pages/101077752/Olympus)
- [API Blueprint](https://blueprint.bukalapak.io/)
- [Datadog](https://app.datadoghq.com/dash/1333113/vp---postpaid---olympus)
- [Opsgenie](https://bukalapak.app.opsgenie.com/teams/dashboard/decb7d53-2e9f-4a5d-a832-e3e95ad533b0/main)
- [Kibana](https://kibana-logs.prod.bukalapak.io/app/kibana#/discover/7157dfa0-aec7-11e9-ae2e-a7183e0a8bb6)

## Onboarding and Development Guide

Following is the required dependencies for olympus.

## Setup
### Prerequisite
1. Ruby 2.6.5
2. Rails 5.1.6
3. MySQL
4. Redis
5. Google Cloud Platform
6. LibSodium

### Installation
#### Install RVM & Ruby

1. RVM
   ```
   curl -L get.rvm.io | bash -s stable
   source ~/.bash_profile
   ```

  Then run `rvm requirements` and follow the instructions

2. Ruby 2.6.5
   ```
   rvm install 2.6.5
   ```

#### Install LibSodium

1. Ubuntu
   ```
   apt-get update
   apt-get install -y libsodium-dev
   ```

2. Mac
   ```
   brew install libsodium
   ```

#### Install Git

1. Register to Github.com. Ask for repo access to admin
2. Install Git
   ```
   sudo apt-get install git
   ```

3. Configure Git
   ```
   git config --global user.name <change_to_ur_name>
   git config --global user.email <change_to_ur_git_email>
   ```

4. Generate Public Key
   ```
   ssh-keygen # then, just press enter
   ```

5. [Add key to Github](https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/)
   ```
   cat ~/.ssh/id_rsa.pub # copy the content to github
   ```

#### Install Olympus

1. Clone repository
   ```
   git clone git@git.gitlab.cloud.bukalapak.io:bukalapak/olympus.git
   cd olympus
   ```

2. Create gemset, install bundler and other dependencies. It can take a while to finish all process.
   ```
   // RVM
   rvm use 2.6.5@olympus --create
   // RBENV
   rbenv install 2.6.5

   rvm gemset create olympus
   rvm 2.6.5@olympus

   gem install bundler -v 1.17.3
   bundle install
   ```

3. Copy env.sample to .env
   ```
   cp env.sample .env
   ```
   Make sure these lines on file .env have correct value depending on your MySQL setup.
   ```
   DATABASE_USERNAME=root
   DATABASE_PASSWORD=<your_password>
   ```

4. Init database and run database migration:
   ```
   // Install and start local MySQL
   brew install mysql
   brew services start mysql

   // Later after use
   brew services stop mysql
   ```
   ```
   rake db:create
   rake db:migrate
   rake db:seed
   ```
   If you are unable to run the test proprly, you can run this command

   Rails
   ```
   rake db:test:prepare RAILS_ENV=test
   rake db:test:load RAILS_ENV=test
   ```

   Sinatra
   ```
   rake db:test:prepare RACK_ENV=test
   rake db:test:load RACK_ENV=test
   ```

5. Run seeder
   ```
   rails r db/seeds.rb
   ```

#### Running Olympus

1. Run application and services
   ```
   rails s -p 8086
   ```

2. Access it at `http://0.0.0.0:8086`

#### Running Olympus Background

1. Run the background process
   ```
   bundle exec bin/background
   ```

## Docker Setup


### Prerequisite
1. Docker and Docker Compose or Docker Desktop

### Running Olympus

1. Setup containers
   ```
   docker-compose up -d
   ```

2. Test public endpoint

   ```
   curl localhost:8086/healthz
   ok%
   ```

3. Generate access token

   ```
   docker-compose exec -ti app bash
   /opt/app# ruby script/generate_access_token.rb # See tmp/access_token.txt
   ```

4. Test private endpoint

   ```
   # See tmp/access_token.txt
   curl -vH 'Authorization: Token <token>' localhost:8086/pdam/transaction-configs

   {"data":{"has_transacted":true},"meta":{"http_status":200}}%
   ```

5. Accessing the rails console
   ```
   docker-compose exec -ti app rails c
   ```

6. Accessing the bash shell to run rake
   ```
   docker-compose exec -ti app bash
   ```

7. Stopping the containers
   ```
   docker-compose down
   ```

## Contributing

1. Make new branch with descriptive name about your change(s) and checkout to that branch
   ````
   git checkout -b branch_name
   ````

2. Commit and push your change to upstream
   ````
   git commit -m "message"
   git push [remote_name] [branch_name]
   ````

3. Open merge request on `Gitlab`

4. Ask someone to review your code.

5. If your code is approved, then merge into master.

## Request Flows, Endpoints, and Dependencies

### Request Flows

- Public endpoints: `aleppo` -> `olympus` -> `mothership`
- Callbacks: `mothership` -> `olympus` -> `olympus-background`
- Background process: `olympus-background` -> `mothership`

### Endpoints

Please refer to Links section > API Blueprint

### Dependencies

- [Mothership](https://github.com/bukalapak/mothership)
- [Aleppo](https://github.com/bukalapak/aleppo)
- MySQL
- [LibSodium](https://libsodium.gitbook.io/doc/)
- All Ruby gems listed in [Gemfile](https://gitlab.cloud.bukalapak.io/bukalapak/olympus/-/blob/master/Gemfile)

## Peru.yaml and Minerva

Since the current [peru.yaml](https://gitlab.cloud.bukalapak.io/bukalapak/olympus/-/blob/master/peru.yaml) has been exclusively assigned to branch [olympus](https://gitlab.cloud.bukalapak.io/infra/gitops/minerva/-/tree/olympus) on [Minerva](https://gitlab.cloud.bukalapak.io/infra/gitops/minerva), please do steps below to update the ENV on Minerva:
1. Create a new MR on Minerva for new changes
2. Merge it into master after review
3. Rebase this [Olympus MR on Minerva](https://gitlab.cloud.bukalapak.io/infra/gitops/minerva/-/merge_requests/21633) (resolve conflict if any).
4. You are ready to release (optionally you can check on the pipeline artifact for making sure the changes have been applied accordingly).
