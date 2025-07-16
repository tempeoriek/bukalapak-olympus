source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '5.2.8'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# bundle exec rake doc:rails generates the API under doc/api.
gem 'aasm' # aasm is a state machine library for Ruby objects
gem 'addressable', '2.8.0' # Addressable is an alternative implementation to the URI implementation that is part of Ruby's standard library
gem 'circuitbox', '~> 2.0.0.pre4' # Circuitbox is a circuit breaker implementation for Ruby
gem 'dogstatsd-ruby' # A Ruby client for DogStatsD
gem 'dotenv-rails' # Dotenv is a zero-dependency gem for loading environment variables from a .env file into ENV in development
gem 'google-cloud-pubsub' # Google Cloud
gem 'google-protobuf', '3.19.2', platforms: ['ruby'] # Google Protocol Buffers
gem 'grpc', '1.21.0', platforms: ['ruby'] # gRPC is a high performance, open-source universal RPC framework
gem 'haml' # Haml (HTML Abstraction Markup Language) is a layer on top of HTML or XML that's designed to express the structure of documents in a non-repetitive, elegant, and easy way
gem 'hex_string' # HexString is a simple library for working with hexadecimal strings
gem 'honeybadger', '~> 3.1' # Honeybadger is a Ruby gem that integrates with the Honeybadger.io service. Not used anymore.
gem 'iso8583' # ISO8583 is a Ruby library for packing and unpacking ISO8583 messages
gem 'jwt' # A pure ruby implementation of the RFC 7519 OAuth JSON Web Token (JWT) standard
gem 'lhm' # Large Hadron Migrator (LHM) is a tool for changing large tables without locking the database. Not maintained anymore, use lhm-shopify instead.
gem 'lograge' # Lograge is an attempt to bring sanity to Rails' noisy and unusable, unparsable and unstructured log output
gem 'logstash-event' # LogStash::Event is a simple event class that is used to transport event data from inputs to outputs
gem 'logstash-logger' # LogstashLogger extends Ruby's Logger class to log directly to Logstash
gem 'luhn-ruby' # Luhn is a Ruby library for generating and validating Luhn numbers
gem 'moneta' # Moneta provides a standard interface for interacting with various kinds of key/value stores
gem 'mws_api_client', git: 'git@git.gitlab.cloud.bukalapak.io:bukalapak/mws-api-ruby-client', tag: 'v0.2.0' # MWS API Ruby Client
gem 'mysql2' # A modern, simple and very fast Mysql library for Ruby - binding to libmysql
gem 'net-sftp' # Net::SFTP is a pure-Ruby implementation of the SFTP protocol
gem 'neo_client', git: 'git@git.gitlab.cloud.bukalapak.io:bukalapak/neo-client-rb', tag: 'v0.2.0' # NeoClient feature toggle and config store.
gem 'nokogiri', '>= 1.13.6' # Nokogiri is an HTML, XML, SAX, and Reader parser
gem 'openssl' # Ruby/OpenSSL is an OpenSSL binding for Ruby
gem 'premailer' # Premailer is a Ruby library that transforms CSS styles into inline style attributes
gem 'pry-rails' # Pry is a runtime developer console and IRB alternative with powerful introspection capabilities. 
gem 'pry-byebug' # Pry-byebug is an extension for pry that adds step-by-step debugging and stack navigation capabilities. 
gem 'puma', '>= 5.6.4' # Puma is a simple, fast, threaded, and highly concurrent HTTP 1.1 server for Ruby/Rack applications
gem 'rack-cors' # Rack::Cors provides support for Cross-Origin Resource Sharing (CORS) for Rack compatible web applications
gem 'rbnacl', '5.0.0' # RbNaCl is a Ruby binding to the Networking and Cryptography (NaCl) library
gem 'redis' # A Ruby client that tries to match Redis' API one-to-one, while still providing an idiomatic interface
gem 'require_all' # RequireAll is a simple way to load your code
gem 'rest-client', '2.0.1' # A simple HTTP and REST client for Ruby, inspired by the Sinatra microframework style of specifying actions: get, put, post, delete
gem 'rufus-scheduler' # Rufus-scheduler is a Ruby gem for scheduling pieces of code (jobs)
gem 'sievex-ruby', git: 'git@git.gitlab.cloud.bukalapak.io:bukalapak/sievex-ruby', tag: 'v2.0.0' # Sievex Ruby
gem 'sinatra', '2.2.0' # Sinatra is a DSL for quickly creating web applications in Ruby with minimal effort
gem 'sneakers' # Sneakers is a simple, fast background processing framework for Ruby
gem 'toggleable', git: 'https://github.com/bukalapak/toggleable.git', branch: 'palanca-client-stable' # Toggleable is a feature toggle library for Ruby
gem 'tzinfo-data' # TZInfo::Data contains data from the IANA Time Zone Database packaged as Ruby modules for use with TZInfo
gem 'uuid' # UUID provides a simple, easy, and fast way to generate universally unique identifiers
gem 'credit_card_validations' # CreditCardValidations is a simple library to validate credit card numbers

# receipt
gem 'sassc-rails' # SassC::Rails is a Sass/SCSS adapter for the Rails asset pipeline
gem 'haml-rails' # Haml-rails provides Haml generators for Rails 4
gem 'wicked_pdf' # Wicked PDF uses the shell utility wkhtmltopdf to serve a PDF file to a user from HTML
gem 'imgkit' # ImgKit is a Ruby gem that uses wkhtmltoimage to convert HTML to image
gem 'wkhtmltoimage-binary', '0.12.5' # Wkhtmltoimage-binary provides binaries for wkhtmltoimage
gem 'wkhtmltopdf-binary-edge', '~> 0.12.5.1' # Wkhtmltopdf-binary-edge provides binaries for wkhtmltopdf

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  gem 'sass-rails', require: false # Sass-rails is a Sass adapter for the Rails asset pipeline
  gem 'factory_bot_rails', "~> 4.10.0"
  # gem 'factory_bot_rails', "~> 4.11.1" # versi ini ada suggestion tambah rubocop
  gem 'foreman', require: false # Foreman is a manager for Procfile-based applications
  gem 'rspec-rails' # RSpec is a testing tool for Ruby, created for behavior-driven development (BDD)
  # gem 'rubocop-rspec'
  gem 'spring' # Spring is a Rails application preloader
  gem 'webmock' # WebMock allows stubbing HTTP requests and setting expectations on HTTP requests
  gem 'simplecov', require: false # SimpleCov is a code coverage analysis tool for Ruby
  gem 'simplecov-cobertura' # SimpleCov Cobertura is a formatter for SimpleCov that outputs Cobertura XML reports
  gem 'json-schema' # JSON Schema is a vocabulary that allows you to annotate and validate JSON documents
end

group :development do
  gem 'rubocop', require: false
end
