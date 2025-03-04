require 'active_record'
require 'yaml'
require 'redis'


# Set up the environment
ENV['ENV'] ||= 'development'

# Establish connection to the database
config_path = File.expand_path('../app/config/database.yml', __dir__)
db_config = YAML.load_file(config_path, aliases: true)[ENV['ENV']]
ActiveRecord::Base.establish_connection(db_config)

if ENV['ENV'] == 'test'
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  ActiveRecord::Base.logger.level = Logger::DEBUG
end

# Configure Redis
redis_config = YAML.load_file(config_path, aliases: true)['redis']
$redis = Redis.new(
  host: redis_config['host'],
  port: redis_config['port'].to_i,
  db: redis_config['db'],
)

# Load app
['../lib/**/*.rb', '../app/models/**/*.rb'].each do |path|
  Dir[File.join(File.dirname(__FILE__), path)].each { |file| require file }
end
