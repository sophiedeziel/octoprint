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

  describe Octoprint::Printer::ErrorInformation do
    use_octoprint_server

    describe ".get without an error", vcr: { cassette_name: "printer/error/no_error" } do
      subject(:info) { described_class.get }

      it { is_expected.to be_a described_class }
      its(:error)       { is_expected.to eq "" }
      its(:reason)      { is_expected.to eq "" }
      its(:consequence) { is_expected.to be_nil }
      its(:faq)         { is_expected.to be_nil }
      its(:logs)        { is_expected.to be_nil }
      its(:error?)      { is_expected.to be false }
    end

    describe ".get with an error", vcr: { cassette_name: "printer/error/error_present" } do
      subject(:info) { Octoprint::Printer.last_error }

      let(:message) { "Thermal Runaway, system stopped! Heater_ID: bed - Printer halted. kill() called!" }

      it { is_expected.to be_a described_class }

      its(:error?)      { is_expected.to be true }
      its(:error)       { is_expected.to eq message }
      its(:reason)      { is_expected.to eq "firmware" }
      its(:consequence) { is_expected.to eq "emergency" }
      its(:faq)         { is_expected.to eq "firmware-thermal-runaway" }
      its(:faq_url)     { is_expected.to eq "https://faq.octoprint.org/firmware-thermal-runaway" }
      its(:extra)       { is_expected.to be_nil }

      it "returns the terminal lines related to the error" do
        expect(info.logs).to all(be_a(String))
        expect(info.logs).to include "Recv: Error:Thermal Runaway, system stopped! Heater_ID: bed"
        expect(info.logs.last).to eq 'Changing monitoring state from "Operational" to "Error"'
      end
    end
  end

  describe Octoprint::Printer::Command do
    use_octoprint_server

    describe ".send_command", vcr: { cassette_name: "printer/command/send_command" } do
      subject(:send_command) { described_class.send_command("M106") }

      it { expect(send_command).to be true }
    end

    describe ".send_command with parameters", vcr: { cassette_name: "printer/command/send_command_with_parameters" } do
      subject(:send_command) { described_class.send_command("M106 S%(speed)s", parameters: { speed: 128 }) }

      it { expect(send_command).to be true }
    end

    describe ".send_commands", vcr: { cassette_name: "printer/command/send_commands" } do
      subject(:send_commands) { described_class.send_commands(["M18", "M106 S0"]) }

      it { expect(send_commands).to be true }
    end

    describe ".run_script", vcr: { cassette_name: "printer/command/run_script" } do
      subject(:run_script) { described_class.run_script("afterPrintCancelled") }

      it { expect(run_script).to be true }
    end

    describe ".custom_controls", vcr: { cassette_name: "printer/command/custom_controls" } do
      subject(:controls) { described_class.custom_controls }

      it "returns the configured controls" do
        expect(controls).to all(be_a(Octoprint::Printer::CustomControl))
        expect(controls.map(&:name)).to eq ["Fan", "Example for multiple commands", "Reporting"]
      end

      it "returns containers with their children" do
        fan = controls.first
        expect(fan).to be_container
        expect(fan.layout).to eq "horizontal"
        expect(fan.children.map(&:name)).to eq ["Enable Fan", "Disable Fan"]
        expect(fan.children.last.additional_classes).to eq "btn-danger"
        expect(controls.last.collapsed).to be true
      end

      it "returns controls with their inputs" do
        enable_fan = controls.first.children.first
        expect(enable_fan).not_to be_container
        expect(enable_fan.command).to eq "M106 S%(speed)s"

        input = enable_fan.input.first
        expect(input).to be_a Octoprint::Printer::CustomControl::Input
        expect(input.name).to eq "Speed (0-255)"
        expect(input.parameter).to eq "speed"
        expect(input.default).to eq 255
        expect(input.slider).to eq({ min: 0, max: 255 })
      end

      it "returns controls with multiple commands and confirmations" do
        move_x = controls[1].children.first
        expect(move_x.commands).to eq ["G91", "G1 X10 F3000", "G90"]
        expect(move_x.confirm).to start_with "You are about to move the X axis"
      end

      it "returns feedback controls" do
        position = controls.last.children.first
        expect(position.regex).to start_with "X:"
        expect(position.template).to eq "Position: X={0}, Y={1}, Z={2}, E={3}"
        expect(position.key).to be_a String
        expect(position.template_key).to be_a String
      end
    end
  end
end
