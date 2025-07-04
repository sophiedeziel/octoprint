# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Client do
  include_context "with default Octoprint config"

  describe "#request" do
    let(:client) do
      described_class.new(host: host, api_key: api_key)
    end

    it "returns the body as a hash", vcr: { cassette_name: "currentuser" } do
      result = client.request("/api/currentuser")

      expect(result).to be_a Hash
    end

    it "raises when api_key is invalid", vcr: { cassette_name: "job:unauthenticated" } do
      client = described_class.new(host: host, api_key: "invalid")
      action = -> { client.request("/api/job") }
      expect(&action).to raise_error Octoprint::Exceptions::AuthenticationError
    end
  end
end
