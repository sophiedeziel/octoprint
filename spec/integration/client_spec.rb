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
