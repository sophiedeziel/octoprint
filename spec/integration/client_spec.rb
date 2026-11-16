# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Client, type: :integration do
  include_context "with default Octoprint config"

  describe "#request" do
    subject(:current_user) { client.request("/api/currentuser") }

    let(:client) do
      described_class.new(host: host, api_key: api_key)
    end

    it "returns the body as a hash", vcr: { cassette_name: "currentuser" } do
      expect(current_user).to be_a Hash

      expect(current_user).to include(:groups)
      expect(current_user).to include(:name)
      expect(current_user).to include(:permissions)
    end
  end

  describe "API version detection" do
    on_octoprint_versions do |version|
      describe "with api_version: :auto", vcr: { cassette_name: "client/auto_detection" } do
        let(:client) { described_class.new(host: host, api_key: api_key, api_version: :auto) }
        let(:detected) { { "1.11" => %w[1.11.8 1.11], "2.0" => %w[2.0.0rc7 2.0] }.fetch(version) }

        it "asks the server for its version on the first request, once" do
          allow(client.client).to receive(:get).and_call_original

          2.times { client.request("/api/version") }

          # One detection request, then the two requests
          expect(client.client).to have_received(:get).with("/api/version", nil, anything).exactly(3).times
          expect(client.server_version).to eq Gem::Version.new(detected.first)
        end

        it "speaks the latest API the server supports" do
          response = client.request("/api/version")

          expect(client.api_version).to eq Gem::Version.new(detected.last)
          # The 2.0 API dropped the api key, so the header was sent to the 2.0 server only
          expect(response.key?(:api)).to eq(version == "1.11")
        end
      end
    end
  end

  describe "timeouts" do
    include WebMock::API

    after { WebMock.reset! }

    let(:client) { described_class.new(host: host, api_key: api_key, open_timeout: 0.1, timeout: 0.1) }

    it "raises a TimeoutError when the server doesn't answer in time" do
      stub_request(:get, "#{host}/api/version").to_timeout

      expect { client.request("/api/version") }.to raise_error(Octoprint::Exceptions::TimeoutError)
    end

    it "raises a ConnectionError when the server refuses the connection" do
      stub_request(:get, "#{host}/api/version").to_raise(Errno::ECONNREFUSED)

      expect { client.request("/api/version") }.to raise_error(Octoprint::Exceptions::ConnectionError)
    end

    it "can be rescued as a ConnectionError" do
      stub_request(:get, "#{host}/api/version").to_timeout

      expect { client.request("/api/version") }.to raise_error(Octoprint::Exceptions::ConnectionError)
    end
  end
end
