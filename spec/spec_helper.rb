# typed: true
# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/vendor/"

  add_group "Libraries", "lib"
  add_group "Core", "lib/octoprint.rb"
  add_group "Resources", "lib/octoprint/*"
  add_group "Files", "lib/octoprint/files"

  minimum_coverage 100
end

require "octoprint"
require "vcr"
require "rspec/its"
require "pry"
require "dotenv/load"
require "rspec/sorbet"

wip_count = 0
RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.around(:example, :wip) do |exampe|
    WebMock.allow_net_connect!
    VCR.turned_off(ignore_cassettes: true) { exampe.run }
    WebMock.disable_net_connect!
    wip_count += 1
  end
  config.after(:suite) do
    warn "\n\nWarning: don't forget to remove the 'wip' tag before commiting your work" unless wip_count.zero?
  end
end

def octoprint_host
  ENV.fetch("OCTOPRINT_HOST", "http://octoprint.local")
end

def octoprint_api_key
  ENV.fetch("OCTOPRINT_API_KEY", "fake_api_key")
end

# Credentials of a non-admin user, used to record the active login cassettes
def octoprint_login_user
  ENV.fetch("OCTOPRINT_LOGIN_USER", "vcruser")
end

def octoprint_login_password
  ENV.fetch("OCTOPRINT_LOGIN_PASSWORD", "fake_password")
end

RSpec.shared_context "with default Octoprint config" do
  let(:host)    { octoprint_host }
  let(:api_key) { octoprint_api_key }
end

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock
  config.ignore_localhost = false
  config.configure_rspec_metadata!
  config.default_cassette_options = { record: :none, record_on_error: false }

  config.filter_sensitive_data("<HOST>")    { octoprint_host }
  config.filter_sensitive_data("<API_KEY>") { octoprint_api_key }
  config.filter_sensitive_data("<LOGIN_PASSWORD>") { octoprint_login_password }

  # Session keys and cookies (session, remember_token, csrf_token) grant access to the server
  config.before_record do |interaction|
    interaction.response.headers["Set-Cookie"]&.map! { |cookie| cookie.sub(/=[^;]*/, "=<COOKIE>") }
    interaction.response.body = interaction.response.body.gsub(/("session":\s*")[^"]*"/, '\1<SESSION>"')
  end
end

def use_octoprint_server
  before do
    Octoprint.configure(host: host, api_key: api_key)
  end
end
