# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::ServerVersion, type: :integration do
  include_context "with default Octoprint config"

  describe "The version object" do
    subject { described_class.new(api: "0.1", server: "1.7.3", text: "OctoPrint 1.7.3") }

    its(:api)    { is_expected.to eq "0.1" }
    its(:server) { is_expected.to eq "1.7.3" }
    its(:text)   { is_expected.to eq "OctoPrint 1.7.3" }
  end

  describe ".get", vcr: { cassette_name: "server_version/get" } do
    subject { described_class.get }

    before do
      Octoprint.configure(host: host, api_key: api_key)
    end

    it { is_expected.to be_a described_class }
    its(:api)    { is_expected.to eq "0.1" }
    its(:server) { is_expected.to eq "1.9.1" }
    its(:text)   { is_expected.to eq "OctoPrint 1.9.1" }
  end
end
