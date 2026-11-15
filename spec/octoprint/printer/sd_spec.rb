# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Printer::Sd do
  include_context "with default Octoprint config"

  describe "inheritance and configuration" do
    it "inherits from BaseResource" do
      expect(described_class).to be < Octoprint::BaseResource
    end

    it "has correct resource path" do
      expect(described_class.instance_variable_get(:@path)).to eq("/api/printer/sd")
    end

    it "includes AutoInitializable and Deserializable" do
      expect(described_class.new).to be_a(Octoprint::AutoInitializable)
      expect(described_class.new).to be_a(Octoprint::Deserializable)
    end
  end

  describe ".get" do
    let(:sd) { described_class.new(ready: true) }

    before do
      allow(described_class).to receive(:fetch_resource).and_return(sd)
    end

    it "fetches the resource with no arguments" do
      described_class.get

      expect(described_class).to have_received(:fetch_resource).with(no_args)
    end

    it "returns the SD card state" do
      expect(described_class.get).to be(sd)
    end
  end

  describe ".deserialize" do
    it "deserializes the ready flag" do
      expect(described_class.deserialize({ ready: true }).ready).to be(true)
      expect(described_class.deserialize({ ready: false }).ready).to be(false)
    end

    it "has no extra fields for a known response" do
      expect(described_class.deserialize({ ready: true }).extra).to be_nil
    end

    it "collects unknown fields in extra" do
      sd = described_class.deserialize({ ready: true, size: 1024 })

      expect(sd.extra).to eq({ size: 1024 })
    end
  end

  describe ".issue_command" do
    before do
      allow(described_class).to receive(:post).and_return(true)
    end

    it "posts with the correct command" do
      described_class.issue_command(command: "refresh")

      expect(described_class).to have_received(:post).with(params: { command: "refresh" })
    end

    it "returns the post result" do
      expect(described_class.issue_command(command: "refresh")).to be(true)
    end
  end

  describe ".init" do
    before do
      allow(described_class).to receive(:issue_command).and_return(true)
    end

    it "delegates to issue_command with init" do
      described_class.init

      expect(described_class).to have_received(:issue_command).with(command: "init")
    end
  end

  describe ".refresh" do
    before do
      allow(described_class).to receive(:issue_command).and_return(true)
    end

    it "delegates to issue_command with refresh" do
      described_class.refresh

      expect(described_class).to have_received(:issue_command).with(command: "refresh")
    end
  end

  describe ".release" do
    before do
      allow(described_class).to receive(:issue_command).and_return(true)
    end

    it "delegates to issue_command with release" do
      described_class.release

      expect(described_class).to have_received(:issue_command).with(command: "release")
    end
  end
end
