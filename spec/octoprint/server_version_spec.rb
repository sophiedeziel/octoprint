# frozen_string_literal: true

RSpec.describe Octoprint::ServerVersion do
  include_context "Octoprint config"

  describe "The version object" do
    subject { Octoprint::ServerVersion.new(api: "0.1", server: "1.7.3", text: "OctoPrint 1.7.3") }

    its(:api)    { is_expected.to eq "0.1" }
    its(:server) { is_expected.to eq "1.7.3" }
    its(:text)   { is_expected.to eq "OctoPrint 1.7.3" }
  end

  describe ".get", vcr: { cassette_name: "server_version/get" } do
    before do
      Octoprint.configure(host: host, api_key: api_key)
    end

    subject { Octoprint::ServerVersion.get }

    it { is_expected.to be_a Octoprint::ServerVersion }
    its(:api)    { is_expected.to eq "0.1" }
    its(:server) { is_expected.to eq "1.7.3" }
    its(:text)   { is_expected.to eq "OctoPrint 1.7.3" }
  end
end
