# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Connection do
  include_context "with default Octoprint config"

  let(:connection_params) do
    {
      current: {
        state: "Operational",
        port: "/dev/ttyACM0",
        baudrate: 250_000,
        printer_profile: "_default"
      },
      options: {
        ports: ["/dev/ttyACM0", "VIRTUAL"],
        baudrates: [250_000, 230_400, 115_200, 57_600, 38_400, 19_200, 9600],
        printer_profiles: [{ name: "Default", id: "_default" }],
        port_preference: "/dev/ttyACM0",
        baudrate_preference: 250_000,
        printer_profile_preference: "_default",
        autoconnect: true
      }
    }
  end

  describe "The connection object" do
    subject { described_class.new(**connection_params) }

    its(:current) { is_expected.to be_a Octoprint::Connection::Settings }
    its(:options) { is_expected.to be_a Octoprint::Connection::Options }
  end

  describe ".get", vcr: { cassette_name: "connection/get" } do
    subject { described_class.get }

    before do
      Octoprint.configure(host: host, api_key: api_key)
    end

    it { is_expected.to be_a described_class }
    its(:current) { is_expected.to be_a Octoprint::Connection::Settings }
    its(:options) { is_expected.to be_a Octoprint::Connection::Options }
  end

  describe "#disconnect", vcr: { cassette_name: "connection/disconnect" } do
    subject { described_class.disconnect }

    before do
      Octoprint.configure(host: host, api_key: api_key)
    end

    it { is_expected.to be true }
  end

  describe "#connect", vcr: { cassette_name: "connection/connect" } do
    subject { described_class.connect }

    before do
      Octoprint.configure(host: host, api_key: api_key)
    end

    it { is_expected.to be true }
  end

  describe "#fake_ack", vcr: { cassette_name: "connection/fake_ack" } do
    subject { described_class.fake_ack }

    before do
      Octoprint.configure(host: host, api_key: api_key)
    end

    it { is_expected.to be true }
  end
end
