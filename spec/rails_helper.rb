# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
ENV['WHITELIST_BNI'] = 'acctest1:acctest2'

require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'spec_helper'
require 'rspec/rails'
require 'support/factory_bot'
require 'support/auth_helper'

include ::Postpaid::Constant
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  # Stub form from access toggle in redis
  config.before(:each) do
    allow(DatadogMetric).to receive(:histogram)
    allow(DatadogMetric).to receive(:increment)
    allow(Toggles::WhitelistBukopin).to receive(:active?).and_return(true)
    allow(Toggles::WhitelistAyoConnect).to receive(:active?).and_return(true)
    allow(Toggles::WhitelistTektaya).to receive(:active?).and_return(true)
    allow(Toggles::WhitleistPdamAllOperator).to receive(:active?).and_return(false)
    allow(::Toggles::Pubsub).to receive(:active?).and_return(true)
    allow(::Toggles::Mws).to receive(:active?).and_return(false)
    allow(::Toggles::OlympusSievexSend).to receive(:active?).and_return(true)
    allow(::Toggles::CryptoHashSensitiveData).to receive(:active?).and_return(true)
    allow(::Toggles::BpjsKetenagakerjaanAyoconnectMock).to receive(:active?).and_return(false)
    allow(::Toggle::AutoRefundConfirmTransactionNotFound).to receive(:active?).and_return(false)
    allow_any_instance_of(Channel::Bukopin::ElectricityPostpaid).to receive(:is_closed_time?).and_return(false)
    allow(Toggle::CircuitBreaker::Thor).to receive(:active?).and_return(false)
  end
end

def request_double(url: 'http://example.com', method: 'get')
  double('request', url: url, uri: URI.parse(url), method: method,
         user: nil, password: nil, cookie_jar: HTTP::CookieJar.new,
         redirection_history: nil, args: {url: url, method: method})
end

RSpec::Matchers.define :match_response_schema do |schema|
  match do |response|
    schema_directory = "#{Dir.pwd}/spec/support/schemas"
    schema_path = "#{schema_directory}/#{schema}.json"
    JSON::Validator.validate!(schema_path, response.body, strict: true)
  end
end
