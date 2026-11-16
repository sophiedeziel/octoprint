# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint do
  include_context "with default Octoprint config"

  it "has a version number" do
    expect(Octoprint::VERSION).not_to be_nil
  end

  describe "configure" do
    it "has a configure method" do
      expect(described_class).to respond_to :configure
    end

    it "configures the api client" do
      described_class.configure(host: host, api_key: api_key)

      expect(described_class.client).not_to be_nil
    end

    it "uses the default timeouts" do
      described_class.configure(host: host, api_key: api_key)

      expect(described_class.client).to have_attributes(open_timeout: 2, timeout: 3)
    end

    it "passes the timeouts to the client" do
      described_class.configure(host: host, api_key: api_key, open_timeout: 1, timeout: nil)

      expect(described_class.client).to have_attributes(open_timeout: 1, timeout: nil)
    end

    it "uses the 1.11 API by default" do
      described_class.configure(host: host, api_key: api_key)

      expect(described_class.client.requested_api_version).to eq "1.11"
    end

    it "passes the API version to the client" do
      described_class.configure(host: host, api_key: api_key, api_version: "2.0")

      expect(described_class.client.api_version).to eq Octoprint::ApiVersion::V2_0
    end

    it "returns nil" do
      result = described_class.configure(host: host, api_key: api_key)

      expect(result).to be_nil
    end
  end
end
