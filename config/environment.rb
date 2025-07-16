# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

# ignore LHM
ActiveRecord::SchemaDumper.ignore_tables << /^lhma_/
# ActiveRecord::Base.logger = Logger.new(STDOUT) if ENV['RACK_ENV']="development"
