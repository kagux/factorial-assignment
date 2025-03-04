ENV["ENV"] = "test"
require_relative "../src/lib/environment"
require "factory_bot"
require "faker"
require "database_cleaner/active_record"

# Load factories
Dir[File.join(File.dirname(__FILE__), "factories/**/*.rb")].each { |file| require file }

# Load support files
Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each { |file| require file }

# Load all support files
Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.order = :random
  Kernel.srand config.seed

  # Factory Bot configuration
  config.include FactoryBot::Syntax::Methods

  # Database Cleaner configuration
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end