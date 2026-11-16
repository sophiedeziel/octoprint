# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Connection::Legacy do
  let(:path) { "/api/connection" }

  def post_request(body)
    Octoprint::ApiRequest.new(http_method: :post, path: path, body: body)
  end

  describe ".to_request" do
    it "sends the serial connector's parameters as the old port and baudrate" do
      request = post_request(command: "connect", connector: "serial",
                             parameters: { port: "VIRTUAL", baudrate: 115_200 },
                             printerProfile: "_default", save: true, autoconnect: false)

      expect(described_class.to_request(request).body).to eq(
        command: "connect", port: "VIRTUAL", baudrate: 115_200, printerProfile: "_default", save: true,
        autoconnect: false
      )
    end

    it "drops the connector when there are no parameters, so OctoPrint autodetects" do
      request = post_request(command: "connect", connector: "serial")

      expect(described_class.to_request(request).body).to eq(command: "connect")
    end

    it "only keeps the parameters 1.x knows" do
      request = post_request(command: "connect", connector: "serial", parameters: { port: "VIRTUAL", other: 1 })

      expect(described_class.to_request(request).body).to eq(command: "connect", port: "VIRTUAL")
    end

    it "sends repair as fake_ack" do
      converted = described_class.to_request(post_request(command: "repair"))

      expect(converted).to eq post_request(command: "fake_ack")
    end

    it "leaves the other commands alone" do
      request = post_request(command: "disconnect")

      expect(described_class.to_request(request)).to be request
    end

    it "leaves requests without a body alone" do
      request = Octoprint::ApiRequest.new(http_method: :get, path: path)

      expect(described_class.to_request(request)).to be request
    end
  end

  describe ".from_response" do
    let(:get_request) { Octoprint::ApiRequest.new(http_method: :get, path: path) }

    # spec/cassettes/2_0/connection/api_1_11/connect_serial.yml: OctoPrint 2.0 without the version header
    let(:legacy_connected) do
      {
        current: { baudrate: 115_200, port: "VIRTUAL", printer_profile: "_default", state: "Operational" },
        options: {
          autoconnect: false, baudrate_preference: nil, baudrates: [115_200, 250_000, 230_400, 57_600],
          port_preference: nil, ports: ["/dev/cu.debug-console", "VIRTUAL"], printer_profile_preference: "_default",
          printer_profiles: [{ id: "_default", name: "Default" }]
        }
      }
    end

    # spec/cassettes/2_0/connection/connect_serial.yml: the same server, with the version header
    let(:connected) do
      {
        current: { capabilities: { job_on_hold: true, temperature_offsets: true }, connector: "serial",
                   parameters: { baudrate: 115_200, port: "VIRTUAL" }, profile: "_default", state: "Operational" },
        options: {
          connectors: [{ connector: "serial", name: "Serial Connection",
                         parameters: { baudrate: [115_200, 250_000, 230_400, 57_600],
                                       port: ["/dev/cu.debug-console", "VIRTUAL"] } }],
          preferred_connector: { connector: "serial", parameters: { baudrate: nil, port: nil } },
          preferred_profile: "_default",
          profiles: [{ id: "_default", name: "Default" }]
        }
      }
    end

    # spec/cassettes/connection/get_disconnected.yml: OctoPrint 1.11.8
    let(:legacy_disconnected) do
      {
        current: { baudrate: nil, port: nil, printer_profile: "_default", state: "Closed" },
        options: {
          baudrate_preference: nil, baudrates: [250_000, 115_200], port_preference: nil, ports: ["VIRTUAL"],
          printer_profile_preference: "_default", printer_profiles: [{ id: "_default", name: "Default" }]
        }
      }
    end

    it "gives the 2.0 shape the server answers with the version header" do
      converted = described_class.from_response(legacy_connected, get_request)

      expect(converted).to eq(
        current: connected[:current].merge(capabilities: nil),
        options: connected[:options].merge(autoconnect: false)
      )
    end

    it "has no connector and empty parameters while disconnected" do
      current = described_class.from_response(legacy_disconnected, get_request)[:current]

      expect(current).to eq(state: "Closed", connector: nil, parameters: {}, capabilities: nil, profile: "_default")
    end

    it "makes a single serial connector of the options" do
      options = described_class.from_response(legacy_disconnected, get_request)[:options]

      expect(options).to eq(
        connectors: [{ connector: "serial", name: "Serial Connection",
                       parameters: { port: ["VIRTUAL"], baudrate: [250_000, 115_200] } }],
        preferred_connector: { connector: "serial", parameters: { port: nil, baudrate: nil } },
        preferred_profile: "_default",
        profiles: [{ id: "_default", name: "Default" }],
        autoconnect: nil
      )
    end

    it "tolerates missing keys" do
      converted = described_class.from_response({}, get_request)

      expect(converted[:current]).to include(connector: nil, parameters: {})
      expect(converted[:options]).to include(profiles: [])
      expect(converted[:options][:connectors].sole[:parameters]).to eq(port: [], baudrate: [])
    end

    it "returns the response of a command unchanged" do
      expect(described_class.from_response(true, post_request(command: "connect"))).to be true
    end
  end
end
