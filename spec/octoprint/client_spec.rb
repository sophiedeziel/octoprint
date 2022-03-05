# frozen_string_literal: true

RSpec.describe Octoprint::Client do
  include_context "Octoprint config"

  it "raises when host is missing" do
    expect do
      Octoprint::Client.new(host: nil, api_key: api_key)
    end.to raise_error Octoprint::Exceptions::MissingCredentials
  end

  it "raises when api_key is missing" do
    expect { Octoprint::Client.new(host: host, api_key: nil) }.to raise_error Octoprint::Exceptions::MissingCredentials
  end

  describe "#request" do
    let(:client) do
      Octoprint::Client.new(host: host, api_key: api_key)
    end

    it "returns the body as a hash", vcr: { cassette_name: "currentuser" } do
      result = client.request("/api/currentuser")

      expect(result).to be_a Hash
    end

    it "raises when api_key is invalid", vcr: { cassette_name: "job:unauthenticated" } do
      client = Octoprint::Client.new(host: host, api_key: "invalid")
      action = -> { client.request("/api/job") }
      expect(&action).to raise_error Octoprint::Exceptions::AuthenticationError
    end
  end
end
