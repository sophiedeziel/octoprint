# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in octoprint.gemspec
gemspec

group :test do
  gem "rspec", "~> 3.0"
  gem "rspec-its"
  gem "simplecov", require: false
  gem "vcr"
  gem "webmock"
end

group :development do
  gem "sorbet", "~> 0.5"
end

group :development, :test do
  gem "dotenv", "~> 3.0"
  gem "pry"
  gem "rake", "~> 13.0"
  gem "rspec-sorbet"
  gem "rubocop", "~> 1.77"
  gem "rubocop-rspec", "~> 3.0"
  gem "tapioca", "~> 0.17.5", require: false
  gem "yard"
end
