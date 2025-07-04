# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Client do
  include_context "with default Octoprint config"

  it "raises when host is missing" do
    expect do
      described_class.new(host: nil, api_key: api_key)
    end.to raise_error Octoprint::Exceptions::MissingCredentialsError
  end

  it "raises when api_key is missing" do
    expect do
      described_class.new(host: host, api_key: nil)
    end.to raise_error Octoprint::Exceptions::MissingCredentialsError
  end

  describe "#use" do
    let(:client) do
      described_class.new(host: host, api_key: api_key)
    end

    before do
      Octoprint.configure(host: "http://192.168.0.1", api_key: "a key")
    end

    it "makes all requests in the block as the client" do
      client.use do
        expect(Octoprint.client.host).to eq client.host
      end
    end

    it "sets back the configured client after the block" do
      client.use do
        # Do some operations
      end
      expect(Octoprint.client.host).to eq "http://192.168.0.1"
    end

    it "sets back the configured client after the block after exceptions" do
      client.use { raise StandardError }
    rescue StandardError
      expect(Octoprint.client.host).to eq "http://192.168.0.1"
    end

    it "has config that is not shared with threads" do
      client_in_thread = nil
      Thread.new do
        client_in_thread = Octoprint.client
      end.join
      expect(client_in_thread).to be_nil
    end
  end
end
