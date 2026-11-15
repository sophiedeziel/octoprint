# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Printer::TemperatureResponse do
  describe ".from_response" do
    subject(:heater) { Octoprint::Printer::Tool }

    let(:response) do
      {
        tool0: { actual: 214.8821, target: 220.0, offset: 0 },
        tool1: { actual: 25.3, target: nil, offset: 0 },
        history: [
          { time: 1_395_651_928, tool0: { actual: 214.8821, target: 220.0 }, tool1: { actual: 25.3, target: nil } },
          { tool0: { actual: 212.32, target: 220.0 } }
        ]
      }
    end

    it "builds an instance of the extending class with the heater's current temperature" do
      tool = heater.from_response(response, :tool0)

      expect(tool).to be_a(Octoprint::Printer::Tool)
      expect(tool.actual).to eq 214.8821
      expect(tool.target).to eq 220.0
      expect(tool.offset).to eq 0
    end

    it "picks the heater's readings out of the history" do
      history = heater.from_response(response, :tool0).history

      expect(history).to all(be_a(Octoprint::Printer::TemperatureReading))
      expect(history.map(&:actual)).to eq [214.8821, 212.32]
      expect(history.map(&:time)).to eq [1_395_651_928, nil]
    end

    it "skips history points without the heater" do
      expect(heater.from_response(response, :tool1).history.map(&:actual)).to eq [25.3]
    end

    it "leaves the history nil when it isn't included" do
      expect(heater.from_response({ tool0: { actual: 21.3 } }, :tool0).history).to be_nil
    end

    it "returns an empty heater when it is missing from the response" do
      tool = heater.from_response({}, :tool3)

      expect(tool.actual).to be_nil
      expect(tool.history).to be_nil
    end

    it "collects unknown fields into extra" do
      expect(heater.from_response({ tool0: { actual: 21.3, unit: "C" } }, :tool0).extra).to eq({ unit: "C" })
    end
  end
end
