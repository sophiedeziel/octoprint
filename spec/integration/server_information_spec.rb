# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::ServerInformation, type: :integration do
  include_context "with default Octoprint config"

  describe "The version object" do
    subject { described_class.new(version: "1.9.1", safemode: "settings") }

    its(:version)  { is_expected.to eq "1.9.1" }
    its(:safemode) { is_expected.to eq "settings" }
  end

  describe ".get", vcr: { cassette_name: "server_information/get" } do
    use_octoprint_server

    subject { described_class.get }

    it { is_expected.to be_a described_class }
    its(:version)  { is_expected.to eq "1.9.1" }
    its(:safemode) { is_expected.to be_nil }
  end
end
