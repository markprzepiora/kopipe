require 'rubygems'
require 'bundler/setup'

require 'active_record'
require 'sqlite3'
require 'with_model'
require 'kopipe'

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

RSpec.configure do |config|
  config.extend WithModel
  config.expect_with(:rspec) do |expectations|
    expectations.syntax = :should
  end
  config.mock_with(:rspec) do |mocks|
    mocks.syntax = :should
  end
end
