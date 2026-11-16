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
require_relative "support/octoprint_versions"

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

  config.extend OctoprintVersions::DSL

  # `octoprint: "2.0"` replays cassettes from that version's folder: spec/cassettes/2_0/<cassette_name>
  config.define_derived_metadata(:octoprint) do |metadata|
    server = OctoprintVersions.server(metadata[:octoprint])
    vcr = metadata[:vcr]
    next if vcr.nil? || server.cassette_prefix.nil?
    unless vcr.is_a?(Hash) && vcr[:cassette_name]
      raise ArgumentError, "Specs tagged octoprint: #{server.version.inspect} need a vcr cassette_name"
    end

    metadata[:vcr] = vcr.merge(cassette_name: server.cassette_name(vcr[:cassette_name]))
  end

  config.after(:suite) do
    warn "\n\nWarning: don't forget to remove the 'wip' tag before commiting your work" unless wip_count.zero?
  end
end

# Host of the default (1.11) server. See spec/support/octoprint_versions.rb for the other versions.
def octoprint_host
  OctoprintVersions.server.host
end

# API key of the default (1.11) server
def octoprint_api_key
  OctoprintVersions.server.api_key
end

# Credentials of a non-admin user, used to record the active login cassettes
def octoprint_login_user
  ENV.fetch("OCTOPRINT_LOGIN_USER", "vcruser")
end

def octoprint_login_password
  ENV.fetch("OCTOPRINT_LOGIN_PASSWORD", "fake_password")
end

# Host and API key of the server picked by the `octoprint:` metadata (1.11 when missing)
RSpec.shared_context "with default Octoprint config" do
  let(:octoprint_server) { OctoprintVersions.server(RSpec.current_example.metadata[:octoprint]) }
  let(:host)    { octoprint_server.host }
  let(:api_key) { octoprint_server.api_key }
end

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock
  config.ignore_localhost = false
  config.configure_rspec_metadata!
  config.default_cassette_options = { record: :none, record_on_error: false }

  # <HOST>/<API_KEY> for 1.11, <HOST_2_0>/<API_KEY_2_0> for 2.0: distinct placeholders, so each cassette
  # replays against its own server
  OctoprintVersions.sensitive_data.each do |placeholder, value|
    config.filter_sensitive_data(placeholder) { value }
  end
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
