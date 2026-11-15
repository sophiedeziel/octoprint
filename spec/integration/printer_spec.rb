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

  describe Octoprint::Printer::Printhead do
    use_octoprint_server

    describe ".jog", vcr: { cassette_name: "printer/printhead/jog" } do
      subject(:jog) { described_class.jog(x: 10, y: -5, z: 0.02) }

      it { expect(jog).to be true }
    end

    describe ".jog with absolute coordinates", vcr: { cassette_name: "printer/printhead/jog_absolute" } do
      subject(:jog) { described_class.jog(x: 100, y: 100, absolute: true, speed: 3000) }

      it { expect(jog).to be true }
    end

    describe ".home", vcr: { cassette_name: "printer/printhead/home" } do
      subject(:home) { described_class.home(axes: %i[x y]) }

      it { expect(home).to be true }
    end

    describe ".feedrate", vcr: { cassette_name: "printer/printhead/feedrate" } do
      subject(:feedrate) { described_class.feedrate(105) }

      it { expect(feedrate).to be true }
    end

    describe ".home with an invalid axis", vcr: { cassette_name: "printer/printhead/home_invalid" } do
      subject(:home) { described_class.home(axes: ["w"]) }

      it { expect { home }.to raise_error(Octoprint::Exceptions::BadRequestError, "[400] axis is invalid") }
    end
  end

  describe Octoprint::Printer::Tool do
    use_octoprint_server

    describe ".temperatures", vcr: { cassette_name: "printer/tool/get" } do
      subject(:tools) { described_class.temperatures }

      it "returns the temperature of each tool" do
        expect(tools.size).to eq 1
        expect(tools[0]).to be_a described_class
        expect(tools[0].actual).to be_a Float
        expect(tools[0].target).to be_a Float
        expect(tools[0].offset).to eq 0
        expect(tools[0].history).to be_nil
      end
    end

    describe ".temperatures with history", vcr: { cassette_name: "printer/tool/get_with_history" } do
      subject(:tools) { described_class.temperatures(history: true, limit: 2) }

      it "returns each tool's limited temperature history" do
        expect(tools[0].history.size).to eq 2
        expect(tools[0].history).to all(be_a(Octoprint::Printer::TemperatureReading))
        expect(tools[0].history.first.actual).to be_a Float
        expect(tools[0].history.first.time).to be_nil
      end
    end

    describe ".target", vcr: { cassette_name: "printer/tool/target" } do
      subject(:target) { described_class.target(tool0: 220) }

      it { expect(target).to be true }
    end

    describe ".offset", vcr: { cassette_name: "printer/tool/offset" } do
      subject(:offset) { described_class.offset(tool0: 10) }

      it { expect(offset).to be true }
    end

    describe ".select_tool", vcr: { cassette_name: "printer/tool/select" } do
      subject(:select_tool) { described_class.select_tool("tool0") }

      it { expect(select_tool).to be true }
    end

    describe ".select_tool with an invalid tool", vcr: { cassette_name: "printer/tool/select_invalid" } do
      subject(:select_tool) { described_class.select_tool("hotend") }

      it { expect { select_tool }.to raise_error(Octoprint::Exceptions::BadRequestError) }
    end

    describe ".extrude", vcr: { cassette_name: "printer/tool/extrude" } do
      subject(:extrude) { described_class.extrude(5) }

      it { expect(extrude).to be true }
    end

    describe ".extrude to retract", vcr: { cassette_name: "printer/tool/retract" } do
      subject(:retract) { described_class.extrude(-3, speed: 300) }

      it { expect(retract).to be true }
    end

    describe ".flowrate", vcr: { cassette_name: "printer/tool/flowrate" } do
      subject(:flowrate) { described_class.flowrate(95) }

      it { expect(flowrate).to be true }
    end
  end

  describe Octoprint::Printer::Bed do
    use_octoprint_server

    describe ".temperature", vcr: { cassette_name: "printer/bed/get" } do
      subject(:temperature) { described_class.temperature }

      it "returns the bed temperature" do
        expect(temperature).to be_a described_class
        expect(temperature.actual).to be_a Float
        expect(temperature.target).to be_a Float
        expect(temperature.offset).to eq 0
        expect(temperature.history).to be_nil
      end
    end

    describe ".temperature with history", vcr: { cassette_name: "printer/bed/get_with_history" } do
      subject(:temperature) { described_class.temperature(history: true, limit: 2) }

      it "returns the limited temperature history" do
        expect(temperature.history.size).to eq 2
        expect(temperature.history).to all(be_a(Octoprint::Printer::TemperatureReading))
        expect(temperature.history.first.actual).to be_a Float
      end
    end

    describe ".target", vcr: { cassette_name: "printer/bed/target" } do
      subject(:target) { described_class.target(75) }

      it { expect(target).to be true }
    end

    describe ".offset", vcr: { cassette_name: "printer/bed/offset" } do
      subject(:offset) { described_class.offset(-5) }

      it { expect(offset).to be true }
    end
  end

  describe Octoprint::Printer::Chamber do
    use_octoprint_server

    describe ".temperature", vcr: { cassette_name: "printer/chamber/get" } do
      subject(:temperature) { described_class.temperature }

      it "returns the chamber temperature" do
        expect(temperature).to be_a described_class
        expect(temperature.actual).to be_a Float
        expect(temperature.target).to be_a Float
        expect(temperature.offset).to eq 0
        expect(temperature.history).to be_nil
      end
    end

    describe ".temperature with history", vcr: { cassette_name: "printer/chamber/get_with_history" } do
      subject(:temperature) { described_class.temperature(history: true, limit: 2) }

      it "returns the limited temperature history" do
        expect(temperature.history.size).to eq 2
        expect(temperature.history).to all(be_a(Octoprint::Printer::TemperatureReading))
        expect(temperature.history.first.actual).to be_a Float
      end
    end

    describe ".target", vcr: { cassette_name: "printer/chamber/target" } do
      subject(:target) { described_class.target(50) }

      it { expect(target).to be true }
    end

    describe ".offset", vcr: { cassette_name: "printer/chamber/offset" } do
      subject(:offset) { described_class.offset(-5) }

      it { expect(offset).to be true }
    end
  end

  describe Octoprint::Printer::Sd do
    use_octoprint_server

    describe ".get", vcr: { cassette_name: "printer/sd/get" } do
      subject(:sd) { described_class.get }

      it { is_expected.to be_a described_class }
      its(:ready) { is_expected.to be true }
    end

    describe ".init", vcr: { cassette_name: "printer/sd/init" } do
      subject(:init) { described_class.init }

      it { expect(init).to be true }
    end

    describe ".refresh", vcr: { cassette_name: "printer/sd/refresh" } do
      subject(:refresh) { described_class.refresh }

      it { expect(refresh).to be true }
    end

    describe ".release", vcr: { cassette_name: "printer/sd/release" } do
      subject(:release) { described_class.release }

      it { expect(release).to be true }
    end
  end
end
