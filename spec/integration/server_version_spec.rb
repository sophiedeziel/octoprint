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

  describe ".get against every supported server" do
    on_octoprint_versions do |version|
      describe ".get", vcr: { cassette_name: "server_version/get_by_version" } do
        subject { described_class.get }

        let(:recorded_version) { { "1.11" => "1.11.8", "2.0" => "2.0.0rc7" }.fetch(version) }

        use_octoprint_server

        it { is_expected.to be_a described_class }
        its(:server) { is_expected.to eq recorded_version }
        its(:text)   { is_expected.to eq "OctoPrint #{recorded_version}" }

        # Without the X-OctoPrint-Api-Version header, 2.0 still answers with the 1.x shape
        its(:api)    { is_expected.to eq "0.1" }
      end
    end
  end
end
