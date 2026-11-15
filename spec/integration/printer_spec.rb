# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Printer, type: :integration do
  include_context "with default Octoprint config"

  describe ".get" do
    use_octoprint_server

    context "without options", vcr: { cassette_name: "printer/get" } do
      subject(:printer) { described_class.get }

      it { is_expected.to be_a described_class }
      its(:temperature) { is_expected.to be_a Octoprint::Printer::TemperatureState }
      its(:sd)          { is_expected.to be_a Octoprint::Printer::Sd }
      its(:state)       { is_expected.to be_a Octoprint::Printer::State }

      it "returns the general state" do
        expect(printer.state.text).to eq "Operational"
        expect(printer.state.flags).to be_a Octoprint::Printer::StateFlags
        expect(printer.state.flags.operational).to be true
        expect(printer.state.flags.printing).to be false
        expect(printer.state.flags.ready).to be true
        expect(printer.state.flags.sd_ready).to be true
        expect(printer.state.flags.closed_or_error).to be false
      end

      it "returns the temperatures of every heater" do
        expect(printer.temperature.tools.keys).to eq [:tool0]
        expect(printer.temperature.tool(0)).to be_a Octoprint::Printer::TemperatureData
        expect(printer.temperature.tool(0).actual).to be_a Float
        expect(printer.temperature.bed).to be_a Octoprint::Printer::TemperatureData
        expect(printer.temperature.chamber).to be_a Octoprint::Printer::TemperatureData
        expect(printer.temperature.history).to be_nil
      end

      it "returns the SD state" do
        expect(printer.sd.ready).to be true
      end
    end

    context "with history", vcr: { cassette_name: "printer/get_with_history" } do
      subject(:history) { described_class.get(history: true, limit: 2).temperature.history }

      it "returns the limited temperature history" do
        expect(history.size).to eq 2
        expect(history).to all(be_a(Octoprint::Printer::TemperatureDataPoint))
      end

      it "returns timestamped data points for every heater" do
        point = history.first
        expect(point.time).to be_a Integer
        expect(point.recorded_at).to be_a Time
        expect(point.tool(0).actual).to be_a Float
        expect(point.tool(0).offset).to be_nil
        expect(point.bed).to be_a Octoprint::Printer::TemperatureData
        expect(point.chamber).to be_a Octoprint::Printer::TemperatureData
      end
    end

    context "with excluded fields", vcr: { cassette_name: "printer/get_with_exclude" } do
      subject(:printer) { described_class.get(exclude: %i[temperature sd]) }

      its(:temperature) { is_expected.to be_nil }
      its(:sd)          { is_expected.to be_nil }
      its(:state)       { is_expected.to be_a Octoprint::Printer::State }
    end
  end
end
