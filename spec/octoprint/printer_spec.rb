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
      expect(described_class::EXCLUDABLE_FIELDS).to eq(%w[temperature storage state])
    end

    it "lists the deprecated excludable fields" do
      expect(described_class::DEPRECATED_EXCLUDABLE_FIELDS).to eq("sd" => "storage")
    end

    it "has a legacy converter" do
      expect(described_class.legacy_converter).to be(Octoprint::Printer::Legacy)
    end
  end

  describe ".get" do
    let(:printer) { described_class.new }

    before do
      Octoprint::Deprecation.reset!
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
      described_class.get(exclude: %i[temperature storage])

      expect(described_class).to have_received(:fetch_resource).with(options: { exclude: "temperature,storage" })
    end

    it "joins excluded string fields with commas" do
      described_class.get(exclude: %w[state])

      expect(described_class).to have_received(:fetch_resource).with(options: { exclude: "state" })
    end

    it "combines history, limit and exclude options" do
      described_class.get(history: true, limit: 5, exclude: [:storage, "state"])

      expect(described_class).to have_received(:fetch_resource).with(
        options: { history: true, limit: 5, exclude: "storage,state" }
      )
    end

    context "with the deprecated sd field" do
      it "excludes storage instead" do
        expect { described_class.get(exclude: %i[temperature sd]) }.to output.to_stderr

        expect(described_class).to have_received(:fetch_resource).with(options: { exclude: "temperature,storage" })
      end

      it "excludes storage only once when both names are given" do
        expect { described_class.get(exclude: ["sd", :storage]) }.to output.to_stderr

        expect(described_class).to have_received(:fetch_resource).with(options: { exclude: "storage" })
      end

      it "prints a deprecation warning once" do
        expect { described_class.get(exclude: [:sd]) }
          .to output("[octoprint] Printer.get(exclude: [:sd]) is deprecated: use exclude: [:storage]\n").to_stderr
        expect { described_class.get(exclude: [:sd]) }.not_to output.to_stderr
      end
    end

    context "when the client speaks the 1.x API" do
      let(:client) { Octoprint::Client.new(host: "http://test.local", api_key: "key", api_version: "1.11") }

      before do
        allow(described_class).to receive(:fetch_resource).and_call_original
        allow(client).to receive(:request).and_return(sd: { ready: true }, state: { text: "Operational" })
      end

      around { |example| client.use { example.run } }

      it "excludes sd and reads the storage state from sd" do
        printer = described_class.get(exclude: %i[temperature])

        expect(printer.storage.ready).to be(true)
        expect(client).to have_received(:request).with("/api/printer?exclude=temperature", http_method: :get)
      end

      it "sends sd for an excluded storage" do
        described_class.get(exclude: %i[temperature storage])

        expect(client).to have_received(:request).with("/api/printer?exclude=temperature%2Csd", http_method: :get)
      end
    end

    context "when the client speaks the 2.0 API" do
      let(:client) { Octoprint::Client.new(host: "http://test.local", api_key: "key", api_version: "2.0") }

      before do
        allow(described_class).to receive(:fetch_resource).and_call_original
        allow(client).to receive(:request).and_return(storage: { ready: true }, state: { text: "Operational" })
      end

      around { |example| client.use { example.run } }

      it "sends storage for an excluded storage" do
        described_class.get(exclude: %i[temperature storage])

        expect(client).to have_received(:request)
          .with("/api/printer?exclude=temperature%2Cstorage", http_method: :get)
      end

      it "reads the storage state" do
        expect(described_class.get.storage.ready).to be(true)
      end
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
        storage: { ready: true },
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

    it "deserializes the storage state" do
      expect(printer.storage).to be_a(Octoprint::Printer::Storage)
      expect(printer.storage.ready).to be(true)
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
        expect(printer.storage).to be_nil
        expect(printer.state.text).to eq("Operational")
      end
    end

    context "with unknown fields" do
      let(:data) { { storage: { ready: false }, job: { file: "test.gcode" } } }

      it "collects them in extra" do
        expect(printer.extra).to eq({ job: { file: "test.gcode" } })
      end
    end
  end

  describe "#sd" do
    subject(:printer) { described_class.deserialize({ storage: { ready: true } }) }

    before do
      Octoprint::Deprecation.reset!
    end

    it "returns the storage state" do
      expect { printer.sd }.to output.to_stderr

      expect(printer.sd).to be(printer.storage)
    end

    it "is nil when the storage state is" do
      expect { expect(described_class.new.sd).to be_nil }.to output.to_stderr
    end

    it "prints a deprecation warning once" do
      expect { printer.sd }.to output("[octoprint] Printer#sd is deprecated: use Printer#storage\n").to_stderr
      expect { printer.sd }.not_to output.to_stderr
    end
  end

  describe ".last_error" do
    let(:error_information) { Octoprint::Printer::ErrorInformation.new(error: "", reason: "") }

    before do
      allow(Octoprint::Printer::ErrorInformation).to receive(:get).and_return(error_information)
    end

    it "delegates to ErrorInformation.get" do
      expect(described_class.last_error).to be(error_information)
      expect(Octoprint::Printer::ErrorInformation).to have_received(:get).with(no_args)
    end
  end
end
