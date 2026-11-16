# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::ApiVersion do
  describe ".parse" do
    it "parses a release" do
      expect(described_class.parse("1.11.8")).to eq Gem::Version.new("1.11.8")
    end

    it "parses a release candidate" do
      expect(described_class.parse("2.0.0rc7")).to eq Gem::Version.new("2.0.0rc7")
    end

    it "drops a local build suffix" do
      expect(described_class.parse("2.0.0.dev12+gabc123.dirty")).to eq Gem::Version.new("2.0.0.dev12")
    end

    it "raises for a version it can't parse" do
      expect { described_class.parse("banana!") }
        .to raise_error(ArgumentError, "Can't parse the OctoPrint version \"banana!\"")
    end
  end

  describe ".for_server" do
    {
      "1.11.8" => "1.11",
      "1.9.1" => "1.11",
      "2.0.0rc7" => "2.0",
      "2.0.0.dev12" => "2.0",
      "2.0.0" => "2.0",
      "2.1.3" => "2.0"
    }.each do |server, api|
      it "speaks the #{api} API with OctoPrint #{server}" do
        expect(described_class.for_server(described_class.parse(server))).to eq Gem::Version.new(api)
      end
    end

    it "treats release candidates as 2.0, which a plain Gem::Version comparison wouldn't" do
      expect(Gem::Version.new("2.0.0rc7") >= Gem::Version.new("2.0.0")).to be false
      expect(described_class.for_server(Gem::Version.new("2.0.0rc7"))).to eq described_class::V2_0
    end
  end

  describe ".legacy?" do
    it { expect(described_class.legacy?(described_class::V1_11)).to be true }
    it { expect(described_class.legacy?(described_class::V2_0)).to be false }
  end

  describe ".header_value" do
    it "has no header for the 1.x API" do
      expect(described_class.header_value(described_class::V1_11)).to be_nil
    end

    it "sends 2.0.0 for the 2.0 API" do
      expect(described_class.header_value(described_class::V2_0)).to eq "2.0.0"
    end
  end

  describe ".required_for" do
    it "returns the API version a feature needs" do
      expect(described_class.required_for(:connectors)).to eq described_class::V2_0
    end

    it "raises for an unknown feature" do
      expect { described_class.required_for(:teleport) }.to raise_error(ArgumentError, /Unknown feature :teleport/)
    end
  end
end
