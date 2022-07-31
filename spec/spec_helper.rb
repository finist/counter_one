# frozen_string_literal: true
require "counter_one"

require 'active_record'
require 'sqlite3'

DB_CONFIG = {
  sqlite3: {
    adapter: 'sqlite3',
    database: 'db/test.sqlite3',
  }
}

ActiveRecord::Base.establish_connection(
  DB_CONFIG[ENV['DB'] || :sqlite3]
)

begin
  was, ActiveRecord::Migration.verbose = ActiveRecord::Migration.verbose, false unless ENV['SHOW_MIGRATION_MESSAGES']
  load "#{File.dirname(__FILE__)}/schema.rb"
ensure
  ActiveRecord::Migration.verbose = was unless ENV['SHOW_MIGRATION_MESSAGES']
end

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.logger.level = 1

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
