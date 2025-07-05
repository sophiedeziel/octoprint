# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Logs::References do
  describe "#initialize" do
    let(:references_data) do
      {
        resource: "http://test.local/plugin/logging/logs/octoprint.log",
        download: "http://test.local/downloads/logs/octoprint.log"
      }
    end

    it "initializes with all attributes" do
      references = described_class.new(**references_data)

      expect(references.resource).to eq("http://test.local/plugin/logging/logs/octoprint.log")
      expect(references.download).to eq("http://test.local/downloads/logs/octoprint.log")
    end

    it "initializes with minimal attributes" do
      minimal_data = { resource: "http://test.local/logs/test.log" }
      references = described_class.new(**minimal_data)

      expect(references.resource).to eq("http://test.local/logs/test.log")
      expect(references.download).to be_nil
    end
  end

  describe "inheritance and modules" do
    it "includes AutoInitializable" do
      expect(described_class).to include(Octoprint::AutoInitializable)
    end
  end

  describe "auto_attrs configuration" do
    it "has correct attribute configuration" do
      attrs = described_class.auto_attrs

      expect(attrs[:resource][:type]).to eq(String)
      expect(attrs[:resource][:nilable]).to be true
      expect(attrs[:download][:type]).to eq(String)
      expect(attrs[:download][:nilable]).to be true
    end
  end
end
