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

    it "has a result" do
      result = described_class.configure(host: host, api_key: api_key)

      expect(result).to be_truthy
    end
  end
end
