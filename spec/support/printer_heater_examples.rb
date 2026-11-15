# typed: true
# frozen_string_literal: true

# Shared behaviour of the single heater resources (Octoprint::Printer::Bed and Octoprint::Printer::Chamber).
#
# @param heater [Symbol] The heater's key in the temperature responses (:bed or :chamber)
RSpec.shared_examples "a printer heater" do |heater|
  it "inherits from Heater" do
    expect(described_class).to be < Octoprint::Printer::Heater
  end

  describe ".get" do
    let(:response) do
      {
        heater => { actual: 50.221, target: 70.0, offset: 5 },
        history: [
          { time: 1_395_651_928, heater => { actual: 50.221, target: 70.0 } },
          { time: 1_395_651_926, heater => { actual: 49.1123, target: 70.0 } }
        ]
      }
    end

    before do
      allow(described_class).to receive(:fetch_resource).and_return(response)
    end

    it "fetches the raw resource without options by default" do
      described_class.get

      expect(described_class).to have_received(:fetch_resource).with(deserialize: false, options: {})
    end

    it "requests the temperature history" do
      described_class.get(history: true)

      expect(described_class).to have_received(:fetch_resource).with(deserialize: false, options: { history: true })
    end

    it "requests a limited temperature history" do
      described_class.get(history: true, limit: 2)

      expect(described_class).to have_received(:fetch_resource).with(
        deserialize: false,
        options: { history: true, limit: 2 }
      )
    end

    it "drops the limit when the history isn't requested" do
      described_class.get(limit: 2)

      expect(described_class).to have_received(:fetch_resource).with(deserialize: false, options: {})
    end

    it "returns a temperature state with the heater's data" do
      temperature = described_class.get

      expect(temperature).to be_a(Octoprint::Printer::TemperatureState)
      expect(temperature.public_send(heater)).to be_a(Octoprint::Printer::TemperatureData)
      expect(temperature.public_send(heater).actual).to eq(50.221)
      expect(temperature.public_send(heater).target).to eq(70.0)
      expect(temperature.public_send(heater).offset).to eq(5)
    end

    it "deserializes the history data points" do
      history = described_class.get.history

      expect(history).to all(be_a(Octoprint::Printer::TemperatureDataPoint))
      expect(history.map(&:time)).to eq([1_395_651_928, 1_395_651_926])
      expect(history.last.public_send(heater).actual).to eq(49.1123)
    end
  end

  describe ".issue_command" do
    before do
      allow(described_class).to receive(:post).and_return(true)
    end

    it "posts with the correct command" do
      described_class.issue_command(command: "target")

      expect(described_class).to have_received(:post).with(params: { command: "target" })
    end

    it "merges options into the params" do
      described_class.issue_command(command: "target", options: { target: 75 })

      expect(described_class).to have_received(:post).with(params: { command: "target", target: 75 })
    end

    it "returns the post result" do
      expect(described_class.issue_command(command: "target")).to be(true)
    end
  end

  describe ".target" do
    before do
      allow(described_class).to receive(:issue_command).and_return(true)
    end

    it "delegates to issue_command with the target temperature" do
      described_class.target(75)

      expect(described_class).to have_received(:issue_command).with(command: "target", options: { target: 75 })
    end

    it "turns the heater off with a target of 0" do
      described_class.target(0)

      expect(described_class).to have_received(:issue_command).with(command: "target", options: { target: 0 })
    end
  end

  describe ".offset" do
    before do
      allow(described_class).to receive(:issue_command).and_return(true)
    end

    it "delegates to issue_command with the offset" do
      described_class.offset(-5)

      expect(described_class).to have_received(:issue_command).with(command: "offset", options: { offset: -5 })
    end
  end
end
