# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in octoprint.gemspec
gemspec

gem "sorbet-runtime"

group :test do
  gem "rspec", "~> 3.0"
  gem "rspec-its"
  gem "vcr"
  gem "webmock"
end

group :development, :test do
  gem "dotenv", "~> 2.7"
  gem "pry"
  gem "rake", "~> 13.0"
  gem "rspec-sorbet"
  gem "rubocop", "~> 1.33"
  gem "rubocop-rspec", "~> 2.22"
  gem "sorbet"
  gem "tapioca", require: false
  gem "yard"
end
