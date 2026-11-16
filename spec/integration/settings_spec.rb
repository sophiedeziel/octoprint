# typed: true
# frozen_string_literal: true

# A non-admin user's key, to record the permission-filtered settings of OctoPrint 2.0. Create it on the 2.0 server
# with the admin key: POST /api/plugin/appkeys {"command": "generate", "app": "gem-specs", "user": "vcruser"}
def octoprint_restricted_api_key
  ENV.fetch("OCTOPRINT_RESTRICTED_API_KEY_2_0", "fake_restricted_api_key")
end

VCR.configure do |config|
  config.filter_sensitive_data("<RESTRICTED_API_KEY_2_0>") { octoprint_restricted_api_key }
end

# The settings use the 2.0 key names on every server and API version
RSpec.shared_examples "settings with the 2.0 key names" do |prefix|
  describe ".get", vcr: { cassette_name: "#{prefix}/get_by_version" } do
    subject(:settings) { described_class.get }

    it "has the printer connection settings instead of the serial settings" do
      expect(settings).not_to include(:serial)
      expect(settings[:printer_connection]).to eq(autoconnect: false)
    end

    it "has the serial connector settings in the 2.0 shape" do
      expect(settings.dig(:plugins, :serial_connector)).to include(
        timeout: include(communication: 30.0, connection: 10.0),
        max_communication_timeouts: { idle: 2, long: 5, printing: 5 },
        capabilities: include(autoreport_temp: true, busy_protocol: true),
        blocklisted_ports: [],
        error_handling: "disconnect",
        send_checksum: "print",
        wait_for_start_on_connect: false,
        log: false
      )
    end

    it "uses the blocklist names" do
      expect(settings[:feature]).to include(auto_uppercase_blocklist: %w[M117 M118 M707 M708],
                                            notify_suppressed_commands: "warn")
      expect(settings[:feature]).not_to include(:auto_uppercase_blacklist)
      expect(settings[:server]).to include(plugin_blocklist: include(enabled: false, ttl: 15))
      expect(settings[:server]).not_to include(:plugin_blacklist)
    end

    it "reads the webcam settings" do
      expect(Octoprint::Settings::Webcam.from_settings(settings)).to have_attributes(enabled: true, name: "classic")
    end
  end

  describe ".save with the 2.0 key names",
           vcr: { cassette_name: "#{prefix}/save_2_0_names", match_requests_on: %i[method uri body] } do
    subject(:updated) do
      described_class.save(
        printerConnection: { autoconnect: true },
        feature: { autoUppercaseBlocklist: %w[M117 M118] },
        server: { pluginBlocklist: { ttl: 20 } },
        plugins: { serial_connector: { timeout: { communication: 45.0 }, errorHandling: "cancel" } }
      )
    end

    after do
      described_class.save(
        printerConnection: { autoconnect: false },
        feature: { autoUppercaseBlocklist: %w[M117 M118 M707 M708] },
        server: { pluginBlocklist: { ttl: 15 } },
        plugins: { serial_connector: { timeout: { communication: 30.0 }, errorHandling: "disconnect" } }
      )
    end

    it "saves them, on 1.x servers too" do
      expect(updated[:printer_connection]).to eq(autoconnect: true)
      expect(updated.dig(:feature, :auto_uppercase_blocklist)).to eq %w[M117 M118]
      expect(updated.dig(:server, :plugin_blocklist, :ttl)).to eq 20
      expect(updated.dig(:plugins, :serial_connector, :timeout, :communication)).to eq 45.0
      expect(updated.dig(:plugins, :serial_connector, :error_handling)).to eq "cancel"
    end
  end
end

# OctoPrint 2.0 filters the settings by permission, with every API version. Uses a non-admin user's key.
RSpec.shared_examples "permission-filtered settings" do |prefix|
  let(:api_key) { octoprint_restricted_api_key }

  describe ".get", vcr: { cassette_name: "#{prefix}/get_restricted" } do
    subject(:settings) { described_class.get }

    it "hides the values the user can't read" do
      expect(settings.dig(:server, :online_check)).to eq(enabled: nil, host: nil, interval: nil, name: nil, port: nil)
      expect(settings.dig(:server, :plugin_blocklist)).to eq(enabled: nil, ttl: nil, url: nil)
      expect(settings.dig(:plugins, :serial_connector))
        .to include(error_handling: nil, blocked_commands: [], log: false)
      expect(settings.dig(:plugins, :serial_connector, :timeout, :communication)).to be_nil
    end

    it "keeps the values the user can read" do
      expect(settings.dig(:appearance, :color)).to eq "default"
      expect(settings.dig(:feature, :auto_uppercase_blocklist)).to eq %w[M117 M118 M707 M708]
    end

    it "reads the webcam settings" do
      expect(Octoprint::Settings::Webcam.from_settings(settings)).to have_attributes(enabled: true, name: "classic")
    end
  end
end

RSpec.describe Octoprint::Settings, type: :integration do
  include_context "with default Octoprint config"

  on_octoprint_versions do
    use_octoprint_server

    it_behaves_like "settings with the 2.0 key names", "settings"
  end

  context "with the 1.11 API against OctoPrint 2.0", api_version: "1.11", octoprint: "2.0" do
    use_octoprint_server

    it_behaves_like "settings with the 2.0 key names", "settings/api_1_11"
    it_behaves_like "permission-filtered settings", "settings/api_1_11"
  end

  context "with the 2.0 API", octoprint: "2.0" do
    use_octoprint_server

    it_behaves_like "permission-filtered settings", "settings"

    describe ".reauth_required", vcr: { cassette_name: "settings/reauth_required" } do
      subject(:requirements) { described_class.reauth_required }

      it "lists the settings that need a recent login" do
        expect(requirements).to include(
          access_control: { default_reauthentication_timeout: true },
          server: { commands: true },
          system: { actions: true }
        )
        expect(requirements.dig(:plugins, :eventmanager, :subscriptions)).to be true
      end
    end
  end

  describe ".reauth_required with the 1.11 API" do
    use_octoprint_server

    it "raises before sending a request" do
      expect { described_class.reauth_required }
        .to raise_error(Octoprint::Exceptions::UnsupportedFeatureError, /reauth_required/)
    end
  end

  describe ".get", vcr: { cassette_name: "settings/get" } do
    use_octoprint_server

    subject(:settings) { described_class.get }

    it { is_expected.to be_a Hash }

    it "returns settings structure" do
      expect(settings).to include(:api)
      expect(settings).to include(:appearance)
      expect(settings).to include(:controls)
      expect(settings).to include(:devel)
      expect(settings).to include(:feature)
      expect(settings).to include(:folder)
      expect(settings).to include(:plugins)
      expect(settings).to include(:scripts)
      expect(settings).to include(:printer_connection)
      expect(settings).to include(:server)
      expect(settings).to include(:system)
      expect(settings).to include(:temperature)
      expect(settings).to include(:webcam)
    end

    it "keeps the 1.x serial settings that have no 2.0 equivalent" do
      expect(settings.dig(:plugins, :serial_connector)).to include(:port, :baudrate, :port_options, :baudrate_options)
    end

    it "returns appearance settings" do
      expect(settings[:appearance]).to include(:name)
      expect(settings[:appearance]).to include(:color)
    end

    it "returns feature flags" do
      expect(settings[:feature]).to be_a Hash
    end
  end

  # Same request as `.get`, so it reuses the recorded settings of a vanilla OctoPrint 1.11 server
  describe ".webcam", vcr: { cassette_name: "settings/get" } do
    use_octoprint_server

    subject(:webcam) { described_class.webcam }

    it { is_expected.to be_a Octoprint::Settings::Webcam }

    it "returns the default webcam of the multi-webcam settings" do
      expect(webcam).to have_attributes(
        enabled: true,
        name: "classic",
        display_name: "Classic Webcam",
        stream_url: "/webcam/?action=stream",
        snapshot_url: "http://localhost:8080/?action=snapshot",
        stream_ratio: "16:9",
        flip_h: false,
        flip_v: false,
        rotate90: false
      )
    end
  end

  describe ".save", vcr: { cassette_name: "settings/save" } do
    use_octoprint_server

    subject(:updated_settings) do
      described_class.save(
        appearance: {
          color: "blue",
          name: "New Name"
        }
      )
    end

    let!(:previous_settings) { described_class.get }

    after do
      described_class.save(previous_settings)
    end

    it { is_expected.to be_a Hash }

    it "returns updated settings" do
      expect(updated_settings).to include(:appearance)
      expect(updated_settings[:appearance][:color]).to eq("blue")
      expect(updated_settings[:appearance][:name]).to eq("New Name")
    end

    it "preserves other settings" do
      expect(updated_settings[:feature]).to eq(previous_settings[:feature])
      expect(updated_settings[:folder]).to eq(previous_settings[:folder])
      expect(updated_settings[:system]).to eq(previous_settings[:system])
    end
  end

  describe ".save with partial update", vcr: { cassette_name: "settings/save_partial" } do
    use_octoprint_server

    subject(:partial_update) do
      described_class.save(
        appearance: {
          color: "green"
        }
      )
    end

    it "updates only specified fields" do
      expect(partial_update[:appearance][:color]).to eq("green")
      expect(partial_update[:appearance][:name]).to be_present
    end
  end

  describe ".regenerate_api_key", vcr: { cassette_name: "settings/regenerate_api_key" } do
    use_octoprint_server

    subject(:api_key_result) { described_class.regenerate_api_key }

    it { is_expected.to be_a Hash }

    it "returns new API key" do
      expect(api_key_result).to include(:apikey)
      expect(api_key_result[:apikey]).to be_a String
      expect(api_key_result[:apikey]).not_to be_empty
    end

    it "returns a different key than the current one", vcr: { cassette_name: "settings/regenerate_api_key_twice" } do
      previous_key = described_class.regenerate_api_key[:apikey]
      expect(api_key_result[:apikey]).not_to eq previous_key
    end
  end

  describe ".fetch_templates", vcr: { cassette_name: "settings/fetch_templates" } do
    use_octoprint_server

    subject(:templates) { described_class.fetch_templates }

    it { is_expected.to be_a Hash }

    it "returns template component identifiers" do
      # The exact structure depends on the OctoPrint installation
      # but it should return a hash with component identifiers. This is tested using a vanilla octoprint instance
      expect(templates).to include(:order)
      expect(templates[:order]).to include(:about)
      expect(templates[:order]).to include(:generic)
    end
  end
end
