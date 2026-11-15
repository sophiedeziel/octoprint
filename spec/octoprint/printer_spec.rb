# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Printer do
  include_context "with default Octoprint config"

  describe "inheritance and configuration" do
    it "inherits from BaseResource" do
      expect(described_class).to be < Octoprint::BaseResource
    end

    it "has correct resource path" do
      expect(described_class.instance_variable_get(:@path)).to eq("/api/printer")
    end

    it "includes AutoInitializable and Deserializable" do
      expect(described_class.new).to be_a(Octoprint::AutoInitializable)
      expect(described_class.new).to be_a(Octoprint::Deserializable)
    end

    it "lists the excludable fields" do
      expect(described_class::EXCLUDABLE_FIELDS).to eq(%w[temperature sd state])
    end
  end

  describe ".get" do
    let(:printer) { described_class.new }

    before do
      allow(described_class).to receive(:fetch_resource).and_return(printer)
    end

    it "returns the fetched printer" do
      expect(described_class.get).to be(printer)
    end

    it "fetches the resource without options by default" do
      described_class.get

      expect(described_class).to have_received(:fetch_resource).with(options: {})
    end

    it "requests the temperature history" do
      described_class.get(history: true)

      expect(described_class).to have_received(:fetch_resource).with(options: { history: true })
    end

    it "requests a limited temperature history" do
      described_class.get(history: true, limit: 2)

      expect(described_class).to have_received(:fetch_resource).with(options: { history: true, limit: 2 })
    end

    it "drops the limit when the history isn't requested" do
      described_class.get(limit: 2)

      expect(described_class).to have_received(:fetch_resource).with(options: {})
    end

    it "joins excluded symbol fields with commas" do
      described_class.get(exclude: %i[temperature sd])

      expect(described_class).to have_received(:fetch_resource).with(options: { exclude: "temperature,sd" })
    end

    it "joins excluded string fields with commas" do
      described_class.get(exclude: %w[state])

      expect(described_class).to have_received(:fetch_resource).with(options: { exclude: "state" })
    end

    it "combines history, limit and exclude options" do
      described_class.get(history: true, limit: 5, exclude: [:sd, "state"])

      expect(described_class).to have_received(:fetch_resource).with(
        options: { history: true, limit: 5, exclude: "sd,state" }
      )
    end

    it "raises ArgumentError listing the invalid exclude fields" do
      expect { described_class.get(exclude: %i[temperature foo bar]) }
        .to raise_error(ArgumentError, "Invalid exclude field(s): foo, bar")
    end

    it "does not fetch the resource when an exclude field is invalid" do
      expect { described_class.get(exclude: ["job"]) }.to raise_error(ArgumentError)

      expect(described_class).not_to have_received(:fetch_resource)
    end
  end

  describe ".deserialize" do
    subject(:printer) { described_class.deserialize(data) }

    let(:data) do
      {
        temperature: {
          tool0: { actual: 214.8821, target: 220.0, offset: 0 },
          tool1: { actual: 25.3, target: nil, offset: 0 },
          bed: { actual: 50.221, target: 70.0, offset: 5 },
          history: [
            {
              time: 1_395_651_928,
              tool0: { actual: 214.8821, target: 220.0 },
              bed: { actual: 50.221, target: 70.0 }
            }
          ]
        },
        sd: { ready: true },
        state: {
          text: "Operational",
          flags: {
            operational: true,
            paused: false,
            printing: false,
            cancelling: false,
            pausing: false,
            sd_ready: true,
            error: false,
            ready: true,
            closed_or_error: false
          }
        }
      }
    end

    it "builds a printer" do
      expect(printer).to be_a(described_class)
    end

    it "deserializes the temperature state" do
      expect(printer.temperature).to be_a(Octoprint::Printer::TemperatureState)
      expect(printer.temperature.tool(0).actual).to eq(214.8821)
      expect(printer.temperature.tool(1).target).to be_nil
      expect(printer.temperature.bed.offset).to eq(5)
      expect(printer.temperature.history.first.time).to eq(1_395_651_928)
    end

    it "deserializes the SD card state" do
      expect(printer.sd).to be_a(Octoprint::Printer::Sd)
      expect(printer.sd.ready).to be(true)
    end

    it "deserializes the general state" do
      expect(printer.state).to be_a(Octoprint::Printer::State)
      expect(printer.state.text).to eq("Operational")
      expect(printer.state.flags).to be_a(Octoprint::Printer::StateFlags)
      expect(printer.state.flags.sd_ready).to be(true)
    end

    it "has no extra fields" do
      expect(printer.extra).to be_nil
    end

    context "when fields are excluded" do
      let(:data) { { state: { text: "Operational", flags: { ready: true } } } }

      it "leaves the excluded fields nil" do
        expect(printer.temperature).to be_nil
        expect(printer.sd).to be_nil
        expect(printer.state.text).to eq("Operational")
      end
    end

    context "with unknown fields" do
      let(:data) { { sd: { ready: false }, job: { file: "test.gcode" } } }

      it "collects them in extra" do
        expect(printer.extra).to eq({ job: { file: "test.gcode" } })
      end
    end
  end
end
