# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Connection::Options do
  subject(:options) { described_class.new(**attributes) }

  let(:serial) do
    { connector: "serial", name: "Serial Connection", parameters: { port: ["VIRTUAL"], baudrate: [115_200] } }
  end
  let(:attributes) do
    {
      connectors: [{ connector: "other", name: "Other", parameters: { host: ["printer.local"] } }, serial],
      preferred_connector: { connector: "serial", parameters: { port: "VIRTUAL", baudrate: 115_200 } },
      preferred_profile: "_default",
      profiles: [{ id: "_default", name: "Default" }]
    }
  end

  describe "the deprecated readers" do
    before { allow(Octoprint::Deprecation).to receive(:warn_once) }

    it "read the serial connector" do
      expect(options).to have_attributes(ports: ["VIRTUAL"], baudrates: [115_200], port_preference: "VIRTUAL",
                                         baudrate_preference: 115_200)
      expect(Octoprint::Deprecation).to have_received(:warn_once)
        .with("Connection::Options#ports", "use the serial connector in connectors")
    end

    it "read the profiles" do
      expect(options).to have_attributes(printer_profiles: attributes[:profiles],
                                         printer_profile_preference: "_default")
    end

    context "without a serial connector" do
      let(:attributes) do
        { connectors: [], preferred_connector: { connector: "other", parameters: { port: "x" } } }
      end

      it "return nil" do
        expect(options).to have_attributes(ports: nil, baudrates: nil, port_preference: nil, baudrate_preference: nil)
      end
    end

    context "without options" do
      let(:attributes) { {} }

      it "return nil" do
        expect(options).to have_attributes(ports: nil, port_preference: nil, printer_profiles: nil,
                                           printer_profile_preference: nil)
      end
    end
  end
end
