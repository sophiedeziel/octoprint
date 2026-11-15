# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Printer::Heater do
  it "is a module" do
    expect(described_class).to be_an_instance_of(Module)
  end

  it "is included by the bed and chamber resources" do
    expect([Octoprint::Printer::Bed, Octoprint::Printer::Chamber]).to all(include(described_class))
  end

  it "doesn't make the bed and chamber share a parent class" do
    expect(Octoprint::Printer::Bed.superclass).to eq(Octoprint::BaseResource)
    expect(Octoprint::Printer::Chamber.superclass).to eq(Octoprint::BaseResource)
  end

  it "adds the temperature attributes to the including resource" do
    expect([Octoprint::Printer::Bed, Octoprint::Printer::Chamber]).to all(include(Octoprint::Printer::TemperatureAttributes))
  end

  it "keeps the attributes of each heater separate" do
    expect(Octoprint::Printer::Bed.auto_attrs).not_to be(Octoprint::Printer::Chamber.auto_attrs)
  end

  it "keeps the resource path of each heater separate" do
    expect(Octoprint::Printer::Bed.instance_variable_get(:@path)).to eq("/api/printer/bed")
    expect(Octoprint::Printer::Chamber.instance_variable_get(:@path)).to eq("/api/printer/chamber")
  end
end
