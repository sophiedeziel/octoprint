# typed: false
# frozen_string_literal: true

RSpec.describe Octoprint::Settings::Legacy do
  let(:get_request) { Octoprint::ApiRequest.new(http_method: :get, path: "/api/settings") }

  def post_request(body, path = "/api/settings")
    Octoprint::ApiRequest.new(http_method: :post, path: path, body: body)
  end

  describe ".from_response" do
    subject(:settings) { described_class.from_response(response, get_request) }

    # Parts of spec/cassettes/settings/get_by_version.yml (OctoPrint 1.11.8)
    let(:response) do
      {
        appearance: { color: "default" },
        feature: { auto_uppercase_blacklist: %w[M117 M118 M707 M708], temperature_graph: true },
        server: { plugin_blacklist: { enabled: false, ttl: 15, url: "https://plugins.octoprint.org/blacklist.json" } },
        plugins: { virtual_printer: { enabled: true } },
        system: { actions: [], events: nil },
        serial: {
          autoconnect: false,
          port: nil,
          baudrate: nil,
          port_options: ["VIRTUAL"],
          baudrate_options: [250_000, 115_200],
          exclusive: true,
          log: false,
          timeout_communication: 30.0,
          timeout_sd_status: 1.0,
          max_timeouts_idle: 2,
          max_timeouts_long: 5,
          max_timeouts_printing: 5,
          cap_autoreport_temp: true,
          cap_autoreport_sd_status: true,
          cap_extended_m20: true,
          blacklisted_ports: [],
          blacklisted_baudrates: [],
          wait_for_start: false,
          disconnect_on_errors: true,
          ignore_errors_from_firmware: false,
          always_send_checksum: false,
          never_send_checksum: false,
          notify_suppressed_commands: "warn",
          swallow_ok_after_resend: true
        }
      }
    end

    it "renames the blacklists to blocklists" do
      expect(settings[:feature]).to eq(auto_uppercase_blocklist: %w[M117 M118 M707 M708], temperature_graph: true,
                                       notify_suppressed_commands: "warn")
      expect(settings[:server]).to eq(
        plugin_blocklist: { enabled: false, ttl: 15, url: "https://plugins.octoprint.org/blacklist.json" }
      )
    end

    it "moves autoconnect to the printer connection settings" do
      expect(settings).not_to include(:serial)
      expect(settings[:printer_connection]).to eq(autoconnect: false)
    end

    it "moves the serial settings to the serial connector plugin, in the 2.0 shape" do
      expect(settings[:plugins]).to eq(
        virtual_printer: { enabled: true },
        serial_connector: {
          port: nil,
          baudrate: nil,
          port_options: ["VIRTUAL"],
          baudrate_options: [250_000, 115_200],
          exclusive: true,
          log: false,
          timeout: { communication: 30.0, sd_status: 1.0 },
          max_communication_timeouts: { idle: 2, long: 5, printing: 5 },
          capabilities: { autoreport_temp: true, autoreport_sdstatus: true, extended_m20: true },
          blocklisted_ports: [],
          blocklisted_baudrates: [],
          wait_for_start_on_connect: false,
          error_handling: "disconnect",
          send_checksum: "print",
          # Dropped by 2.0, kept under its 1.x name
          swallow_ok_after_resend: true
        }
      )
    end

    it "keeps the 1.x settings that 2.0 dropped" do
      expect(settings[:system]).to eq(actions: [], events: nil)
    end

    it "doesn't modify the response" do
      expect { settings }.not_to change(response, :deep_dup)
    end

    {
      [true, false] => "disconnect", [false, true] => "ignore", [false, false] => "cancel", [true, true] => "disconnect"
    }.each do |(disconnect, ignore), error_handling|
      it "converts disconnect_on_errors: #{disconnect}, ignore_errors_from_firmware: #{ignore} to #{error_handling}" do
        response[:serial].merge!(disconnect_on_errors: disconnect, ignore_errors_from_firmware: ignore)

        expect(settings.dig(:plugins, :serial_connector, :error_handling)).to eq error_handling
      end
    end

    { [true, false] => "always", [false, true] => "never", [false, false] => "print" }
      .each do |(always, never), send_checksum|
      it "converts always_send_checksum: #{always}, never_send_checksum: #{never} to #{send_checksum}" do
        response[:serial].merge!(always_send_checksum: always, never_send_checksum: never)

        expect(settings.dig(:plugins, :serial_connector, :send_checksum)).to eq send_checksum
      end
    end

    context "with the permission-filtered settings of OctoPrint 2.0" do
      # Parts of spec/cassettes/2_0/settings/api_1_11/get_restricted.yml
      let(:response) do
        {
          feature: { notify_suppressed_commands: "warn", auto_uppercase_blacklist: %w[M117 M118 M707 M708] },
          server: { plugin_blacklist: { enabled: nil, ttl: nil, url: nil } },
          serial: {
            autoconnect: nil, timeout_communication: nil, disconnect_on_errors: nil, ignore_errors_from_firmware: nil,
            always_send_checksum: nil, never_send_checksum: nil, blacklisted_ports: [], log: false,
            notify_suppressed_commands: nil, cap_autoreport_temp: nil, port: nil
          },
          plugins: {
            serial_connector: {
              timeout: {}, error_handling: nil, blocklisted_ports: [], log: false, capabilities: {}, send_checksum: nil
            }
          }
        }
      end

      it "keeps the hidden values hidden" do
        expect(settings[:printer_connection]).to eq(autoconnect: nil)
        expect(settings[:server]).to eq(plugin_blocklist: { enabled: nil, ttl: nil, url: nil })
        expect(settings.dig(:plugins, :serial_connector)).to eq(
          port: nil, log: false, blocklisted_ports: [],
          timeout: { communication: nil }, capabilities: { autoreport_temp: nil },
          error_handling: nil, send_checksum: nil
        )
      end

      it "prefers the 2.0 values the server sent" do
        expect(settings.dig(:feature, :notify_suppressed_commands)).to eq "warn"
      end
    end

    it "converts the settings returned by a save" do
      expect(described_class.from_response(response, post_request({}))).to include(:printer_connection)
    end

    it "returns the responses of the other settings endpoints unchanged" do
      request = Octoprint::ApiRequest.new(http_method: :get, path: "/api/settings/templates")

      expect(described_class.from_response(response, request)).to be response
    end

    it "returns a response without serial settings unchanged" do
      expect(described_class.from_response({ appearance: { color: "red" } }, get_request))
        .to eq(appearance: { color: "red" })
    end

    it "returns a non-hash response unchanged" do
      expect(described_class.from_response(true, get_request)).to be true
    end
  end

  describe ".to_request" do
    subject(:body) { described_class.to_request(post_request(update)).body }

    let(:update) do
      {
        appearance: { color: "blue" },
        printerConnection: { autoconnect: true },
        feature: { autoUppercaseBlocklist: %w[M117], notifySuppressedCommands: "info", temperatureGraph: false },
        server: { pluginBlocklist: { ttl: 20 } },
        plugins: {
          virtual_printer: { enabled: true },
          serial_connector: {
            port: "VIRTUAL",
            timeout: { communication: 45.0, resendOk: 1.0 },
            maxCommunicationTimeouts: { idle: 3 },
            capabilities: { autoreport_temp: false },
            blocklistedPorts: ["/dev/ttyS0"],
            waitForStartOnConnect: true,
            errorHandling: "ignore",
            sendChecksum: "never",
            trustM73: false
          }
        }
      }
    end

    it "renames the 2.0 settings to the 1.x names" do
      expect(body).to eq(
        appearance: { color: "blue" },
        feature: { autoUppercaseBlacklist: %w[M117], temperatureGraph: false },
        server: { pluginBlacklist: { ttl: 20 } },
        plugins: {
          virtual_printer: { enabled: true },
          # Settings 1.x doesn't have stay where they are
          serial_connector: { timeout: { resendOk: 1.0 }, trustM73: false }
        },
        serial: {
          autoconnect: true,
          notifySuppressedCommands: "info",
          port: "VIRTUAL",
          timeoutCommunication: 45.0,
          maxTimeoutsIdle: 3,
          capAutoreportTemp: false,
          blacklistedPorts: ["/dev/ttyS0"],
          waitForStart: true,
          disconnectOnErrors: false,
          ignoreErrorsFromFirmware: true,
          alwaysSendChecksum: false,
          neverSendChecksum: true
        }
      )
    end

    it "removes the sections left empty" do
      body = described_class.to_request(
        post_request(printerConnection: { autoconnect: false }, plugins: { serial_connector: { log: true } })
      ).body

      expect(body).to eq(serial: { autoconnect: false, log: true })
    end

    it "accepts String keys" do
      body = described_class.to_request(post_request({ "printerConnection" => { "autoconnect" => true } })).body

      expect(body).to eq(serial: { autoconnect: true })
    end

    it "merges with 1.x serial settings" do
      body = described_class.to_request(
        post_request(serial: { log: true }, printerConnection: { autoconnect: true })
      ).body

      expect(body).to eq(serial: { log: true, autoconnect: true })
    end

    it "sends snake_case keys unchanged, like OctoPrint 2.0 ignores them" do
      body = described_class.to_request(post_request(printer_connection: { autoconnect: true })).body

      expect(body).to eq(printer_connection: { autoconnect: true })
    end

    it "sends 1.x-only updates unchanged" do
      body = described_class.to_request(post_request(appearance: { name: "Ender" }, plugins: "not a hash")).body

      expect(body).to eq(appearance: { name: "Ender" }, plugins: "not a hash")
    end

    it "doesn't modify the update" do
      expect { body }.not_to change(update, :deep_dup)
    end

    it "sends the other requests unchanged" do
      request = post_request({}, "/api/settings/apikey")

      expect(described_class.to_request(request)).to be request
    end

    it "sends a GET unchanged" do
      expect(described_class.to_request(get_request)).to be get_request
    end
  end
end
