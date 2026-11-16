# typed: true
# frozen_string_literal: true

# Specs for the spec support that records and replays cassettes per OctoPrint server version
RSpec.describe OctoprintVersions do
  describe ".server" do
    it "defaults to 1.11" do
      expect(described_class.server.version).to eq "1.11"
    end

    it "raises for an unknown version" do
      expect { described_class.server("0.9") }.to raise_error(ArgumentError, /Unknown OctoPrint version "0.9"/)
    end
  end

  describe "host and API key" do
    let(:env) { {} }

    before do
      allow(ENV).to receive(:fetch).and_call_original
      %w[OCTOPRINT_HOST_1_11 OCTOPRINT_HOST OCTOPRINT_HOST_2_0].each do |name|
        allow(ENV).to receive(:fetch).with(name) { |_, &block| env.fetch(name) { block.call } }
        allow(ENV).to receive(:fetch).with(name, anything) { |_, default| env.fetch(name, default) }
      end
    end

    it "uses the versioned variable first" do
      env.merge!("OCTOPRINT_HOST_1_11" => "http://one-eleven", "OCTOPRINT_HOST" => "http://legacy")

      expect(described_class.server("1.11").host).to eq "http://one-eleven"
    end

    it "falls back to OCTOPRINT_HOST for 1.11" do
      env["OCTOPRINT_HOST"] = "http://legacy"

      expect(described_class.server("1.11").host).to eq "http://legacy"
    end

    it "does not fall back to OCTOPRINT_HOST for 2.0" do
      env["OCTOPRINT_HOST"] = "http://legacy"

      expect(described_class.server("2.0").host).to eq "http://octoprint2.local"
    end
  end

  describe "#cassette_name" do
    it "keeps 1.11 cassettes in the original layout" do
      expect(described_class.server("1.11").cassette_name("job/get")).to eq "job/get"
    end

    it "prefixes 2.0 cassettes once" do
      server = described_class.server("2.0")

      expect(server.cassette_name(server.cassette_name("job/get"))).to eq "2_0/job/get"
    end
  end

  describe ".sensitive_data" do
    it "has a distinct placeholder per server value" do
      placeholders = described_class.sensitive_data.map(&:first)

      expect(placeholders).to contain_exactly("<HOST>", "<API_KEY>", "<HOST_2_0>", "<API_KEY_2_0>")
    end

    it "lists the longest values first" do
      lengths = described_class.sensitive_data.map { |(_, value)| value.length }

      expect(lengths).to eq lengths.sort.reverse
    end
  end

  describe "octoprint metadata", octoprint: "2.0", vcr: { cassette_name: "some/cassette" } do
    it "replays the version's cassette folder" do |example|
      expect(example.metadata[:vcr][:cassette_name]).to eq "2_0/some/cassette"
    end

    context "with a nested group" do
      it "does not prefix twice" do |example|
        expect(example.metadata[:vcr][:cassette_name]).to eq "2_0/some/cassette"
      end
    end
  end

  describe ".on_octoprint_versions" do
    on_octoprint_versions do |version|
      it "tags the context with the version" do |example|
        expect(example.metadata[:octoprint]).to eq version
      end
    end

    on_octoprint_versions("2.0") do
      include_context "with default Octoprint config"

      it "picks the server's host" do
        expect(host).to eq described_class.server("2.0").host
      end
    end
  end
end
