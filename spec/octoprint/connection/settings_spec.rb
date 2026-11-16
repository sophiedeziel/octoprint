# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Connection::Settings do
  describe "the deprecated readers" do
    before { allow(Octoprint::Deprecation).to receive(:warn_once) }

    it "read the serial parameters and the profile" do
      settings = described_class.new(state: "Operational", connector: "serial",
                                     parameters: { port: "VIRTUAL", baudrate: 115_200 }, profile: "_default")

      expect(settings).to have_attributes(port: "VIRTUAL", baudrate: 115_200, printer_profile: "_default")
      expect(Octoprint::Deprecation).to have_received(:warn_once).with("Connection::Settings#port",
                                                                       "use parameters[:port]")
    end

    it "return nil while disconnected" do
      settings = described_class.new(state: "Offline")

      expect(settings).to have_attributes(port: nil, baudrate: nil, printer_profile: nil)
    end
  end
end
