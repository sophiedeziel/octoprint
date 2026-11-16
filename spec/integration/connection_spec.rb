# typed: true
# frozen_string_literal: true

# Before recording, the printer must be disconnected on both servers. The specs connect the virtual printer
# (port VIRTUAL, 115200 bauds) and disconnect it afterwards.
#
# The connect and repair cassettes also match on the request body, so replaying them checks what the gem sends
# to each API version (e.g. `fake_ack` instead of `repair`, `port`/`baudrate` instead of `parameters` for 1.x).
RSpec.shared_examples "the connection API" do |prefix, api_version|
  let(:virtual_printer) { { port: "VIRTUAL", baudrate: 115_200 } }

  # The virtual printer needs a moment to become operational. Only wait while recording.
  def wait_for_printer
    sleep 3 if VCR.current_cassette&.recording?
  end

  describe ".get while disconnected", vcr: { cassette_name: "#{prefix}/get_disconnected" } do
    subject(:connection) { described_class.get }

    it { is_expected.to be_a described_class }

    it "has no current connector" do
      expect(connection.current).to have_attributes(connector: nil, parameters: {}, capabilities: nil)
    end

    it "lists the serial connector and the values of its parameters" do
      serial = connection.options.connectors.sole

      expect(serial).to have_attributes(connector: "serial", name: "Serial Connection")
      expect(serial.parameters[:port]).to include("VIRTUAL")
      expect(serial.parameters[:baudrate]).to include(115_200, 250_000)
    end

    it "has the preferences" do
      expect(connection.options.preferred_connector).to be_a Octoprint::Connection::PreferredConnector
      expect(connection.options.preferred_connector).to have_attributes(
        connector: "serial", parameters: { port: nil, baudrate: nil }
      )
      expect(connection.options.preferred_profile).to eq "_default"
      expect(connection.options.profiles).to eq [{ id: "_default", name: "Default" }]
    end
  end

  describe ".connect with the serial connector",
           vcr: { cassette_name: "#{prefix}/connect_serial", match_requests_on: %i[method uri body] } do
    subject(:connection) { described_class.get }

    before do
      described_class.connect(connector: "serial", parameters: virtual_printer, printer_profile: "_default")
      wait_for_printer
    end

    after { described_class.disconnect }

    it "connects to the printer" do
      expect(connection.current).to have_attributes(
        state: "Operational", connector: "serial", parameters: virtual_printer, profile: "_default"
      )
    end

    if api_version == "2.0"
      its("current.capabilities") { is_expected.to include(job_on_hold: true, temperature_offsets: true) }
    else
      its("current.capabilities") { is_expected.to be_nil }
    end
  end

  describe ".connect without parameters",
           vcr: { cassette_name: "#{prefix}/connect_autodetect", match_requests_on: %i[method uri body] } do
    subject { described_class.connect }

    after { described_class.disconnect }

    it { is_expected.to be true }
  end

  describe ".connect with the deprecated port and baudrate",
           vcr: { cassette_name: "#{prefix}/connect_serial", match_requests_on: %i[method uri body] } do
    subject(:connection) { described_class.get }

    before do
      allow(Octoprint::Deprecation).to receive(:warn_once)
      described_class.connect(port: "VIRTUAL", baudrate: 115_200, printerProfile: "_default")
    end

    after { described_class.disconnect }

    # Replays the cassette of the connector style: the same requests are sent
    its("current.parameters") { is_expected.to eq virtual_printer }

    it "warns" do
      expect(Octoprint::Deprecation).to have_received(:warn_once)
        .with("Connection.connect(port:, baudrate:, printerProfile:)", /connector: "serial"/)
    end
  end

  describe ".repair", vcr: { cassette_name: "#{prefix}/repair", match_requests_on: %i[method uri body] } do
    before do
      described_class.connect(connector: "serial", parameters: virtual_printer)
      wait_for_printer
    end

    after { described_class.disconnect }

    it { expect(described_class.repair).to be true }

    # Replays the cassette of repair: the same requests are sent
    it "keeps the deprecated fake_ack" do
      Octoprint::Deprecation.reset!
      expect { expect(described_class.fake_ack).to be true }.to output(/fake_ack is deprecated/).to_stderr
    end
  end

  describe ".disconnect", vcr: { cassette_name: "#{prefix}/disconnect" } do
    subject { described_class.disconnect }

    it { is_expected.to be true }
  end
end

RSpec.describe Octoprint::Connection, type: :integration do
  include_context "with default Octoprint config"

  describe "The connection object" do
    subject(:connection) do
      described_class.new(
        current: { state: "Operational", connector: "serial", parameters: { port: "VIRTUAL", baudrate: 115_200 },
                   capabilities: { job_on_hold: true }, profile: "_default" },
        options: {
          connectors: [{ connector: "serial", name: "Serial Connection",
                         parameters: { port: ["VIRTUAL"], baudrate: [115_200] } }],
          preferred_connector: { connector: "serial", parameters: { port: nil, baudrate: nil } },
          preferred_profile: "_default",
          profiles: [{ id: "_default", name: "Default" }]
        }
      )
    end

    its(:current) { is_expected.to be_a Octoprint::Connection::Settings }
    its(:options) { is_expected.to be_a Octoprint::Connection::Options }
    its("options.connectors.first") { is_expected.to be_a Octoprint::Connection::Connector }
    its("options.preferred_connector") { is_expected.to be_a Octoprint::Connection::PreferredConnector }
  end

  on_octoprint_versions do |version|
    use_octoprint_server

    it_behaves_like "the connection API", "connection", version
  end

  context "with the 1.11 API against OctoPrint 2.0", api_version: "1.11", octoprint: "2.0" do
    use_octoprint_server

    it_behaves_like "the connection API", "connection/api_1_11", "1.11"
  end

  describe ".connect with another connector" do
    use_octoprint_server

    it "raises before reaching a 1.x server" do
      expect { described_class.connect(connector: "bogus", parameters: {}) }
        .to raise_error(Octoprint::Exceptions::UnsupportedFeatureError, /connectors/)
    end
  end

  describe ".connect with an unknown connector on 2.0", octoprint: "2.0",
                                                        vcr: { cassette_name: "connection/connect_unknown" } do
    use_octoprint_server

    it "lets the server reject it" do
      expect { described_class.connect(connector: "bogus", parameters: {}) }
        .to raise_error(Octoprint::Exceptions::BadRequestError, /unknown connector/)
    end
  end

  # Recorded in 2022 from a 1.x server connected to a real printer
  describe ".get from a 1.x printer while printing", vcr: { cassette_name: "connection/get" } do
    subject(:connection) { described_class.get }

    use_octoprint_server

    it "converts the port and baudrate to the serial connector" do
      expect(connection.current).to have_attributes(
        state: "Printing", connector: "serial", parameters: { port: "/dev/ttyACM0", baudrate: 250_000 },
        capabilities: nil, profile: "_default"
      )
    end

    it "converts the options to a single serial connector" do
      expect(connection.options.connectors.sole).to have_attributes(
        connector: "serial", name: "Serial Connection",
        parameters: { port: ["/dev/ttyACM0"], baudrate: [250_000, 230_400, 115_200, 57_600, 38_400, 19_200, 9600] }
      )
      expect(connection.options.preferred_connector.parameters).to eq(port: nil, baudrate: 250_000)
      expect(connection.options.profiles).to eq [{ id: "_default", name: "Creality CR-10s" }]
    end

    it "keeps the deprecated readers" do
      Octoprint::Deprecation.reset!
      expect do
        expect(connection.current).to have_attributes(port: "/dev/ttyACM0", baudrate: 250_000,
                                                      printer_profile: "_default")
        expect(connection.options).to have_attributes(
          ports: ["/dev/ttyACM0"], baudrates: include(250_000),
          printer_profiles: [{ id: "_default", name: "Creality CR-10s" }],
          port_preference: nil, baudrate_preference: 250_000, printer_profile_preference: "_default"
        )
      end.to output(/deprecated/).to_stderr
    end
  end
end
