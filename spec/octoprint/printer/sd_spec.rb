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
end
