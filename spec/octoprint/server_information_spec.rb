# frozen_string_literal: true

RSpec.describe Octoprint::ServerInformation do
  include_context "Octoprint config"

  describe "The version object" do
    subject { Octoprint::ServerInformation.new(version: "1.7.3", safemode: "settings") }

    its(:version)  { is_expected.to eq "1.7.3" }
    its(:safemode) { is_expected.to eq "settings" }
  end

  describe ".get", vcr: { cassette_name: "server" } do
    before do
      Octoprint.configure(host: host, api_key: api_key)
    end

    subject { Octoprint::ServerInformation.get }

    it { is_expected.to be_a Octoprint::ServerInformation }
    its(:version)  { is_expected.to eq "1.7.3" }
    its(:safemode) { is_expected.to be_nil }
  end
end
