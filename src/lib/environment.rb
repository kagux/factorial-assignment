require "active_record"
require "yaml"
require "redis"

# Set up the environment
ENV["ENV"] ||= "development"

# Establish connection to the database
config_path = File.expand_path("../app/config/database.yml", __dir__)
db_config = YAML.load_file(config_path, aliases: true)[ENV["ENV"]]

# Use DATABASE_URL if available (useful for CI environments)
if ENV["DATABASE_URL"]
  ActiveRecord::Base.establish_connection(ENV["DATABASE_URL"])
else
  ActiveRecord::Base.establish_connection(db_config)
end

if ENV["ENV"] == "test"
  # ActiveRecord::Base.logger = Logger.new(STDOUT)
  # ActiveRecord::Base.logger.level = Logger::DEBUG
end

# Configure Redis
if ENV["REDIS_URL"]
  $redis = Redis.new(url: ENV["REDIS_URL"])
else
  redis_config = YAML.load_file(config_path, aliases: true)["redis"]
  $redis = Redis.new(
    host: redis_config["host"],
    port: redis_config["port"].to_i,
    db: redis_config["db"],
  )
end

# Load app
["../lib/**/*.rb", "../app/models/**/*.rb"].each do |path|
  Dir[File.join(File.dirname(__FILE__), path)].each { |file| require file }
end
