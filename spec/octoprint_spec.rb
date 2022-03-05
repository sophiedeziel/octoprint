# frozen_string_literal: true

RSpec.describe Octoprint do
  include_context "Octoprint config"

  it "has a version number" do
    expect(Octoprint::VERSION).not_to be nil
  end

  describe "configure" do
    it "has a configure method" do
      expect(Octoprint).to respond_to :configure
    end

    it "configures the api client" do
      result = Octoprint.configure(host: host, api_key: api_key)

      expect(result).to be_truthy
      expect(Octoprint.client).to_not be_nil
    end
  end
end
