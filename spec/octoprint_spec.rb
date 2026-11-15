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

    it "has a result" do
      result = described_class.configure(host: host, api_key: api_key)

      expect(result).to be_truthy
    end
  end
end
