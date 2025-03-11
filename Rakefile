desc "Load the seed data from database/seeds.rb"
task :seed do
  load "database/seeds.rb"
end

desc "Reset database and load seed data"
task :reset => [:drop, :create, :migrate, :seed]

desc "Drop the database"
task :drop do
  sh "PGPASSWORD=posgres docker-compose exec -T db dropdb -U postgres factorial_development || true"
end

desc "Create the database"
task :create do
  sh "PGPASSWORD=posgres docker-compose exec -T db createdb -U postgres factorial_development"
end

desc "Run migrations"
task :migrate do
  sh "PGPASSWORD=posgres docker-compose exec -T db psql -U postgres factorial_development < database/schema.sql"
end
