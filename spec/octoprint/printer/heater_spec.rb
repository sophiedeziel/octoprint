# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Printer::Heater do
  describe "inheritance and configuration" do
    it "inherits from BaseResource" do
      expect(described_class).to be < Octoprint::BaseResource
    end

    it "is abstract and does not define a resource path" do
      expect(described_class.instance_variable_get(:@path)).to be_nil
    end

    it "is the parent of the bed and chamber resources" do
      expect([Octoprint::Printer::Bed, Octoprint::Printer::Chamber]).to all(be < described_class)
    end
  end

  describe "resource paths of subclasses" do
    it "keeps each heater's path separate" do
      expect(Octoprint::Printer::Bed.instance_variable_get(:@path)).to eq("/api/printer/bed")
      expect(Octoprint::Printer::Chamber.instance_variable_get(:@path)).to eq("/api/printer/chamber")
    end
  end
end
