# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::User do
  include_context "with default Octoprint config"

  describe ".current" do
    it "returns a User object", vcr: { cassette_name: "currentuser" } do
      Octoprint.configure(host: host, api_key: api_key)
      user = described_class.current

      expect(user).to be_a(described_class)
      expect(user.name).to be_a(String)
    end

    it "raises error when client not configured" do
      original_client = Octoprint.client
      Octoprint.client = nil

      expect { described_class.current }.to raise_error("No client configured")
    ensure
      Octoprint.client = original_client
    end
  end
end
