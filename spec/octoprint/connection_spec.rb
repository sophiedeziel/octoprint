# frozen_string_literal: true

RSpec.describe Octoprint::Connection do
  include_context "Octoprint config"

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
    subject { Octoprint::Connection.new(**connection_params) }

    its(:current) { is_expected.to be_a Octoprint::Connection::Settings }
    its(:options) { is_expected.to be_a Octoprint::Connection::Options }
  end

  describe ".get", vcr: { cassette_name: "connection" } do
    before do
      Octoprint.configure(host: host, api_key: api_key)
    end

    subject { Octoprint::Connection.get }

    it { is_expected.to be_a Octoprint::Connection }
    its(:current) { is_expected.to be_a Octoprint::Connection::Settings }
    its(:options) { is_expected.to be_a Octoprint::Connection::Options }
  end

  describe "#disconnect", :skip, vcr: { cassette_name: "disconnect" } do
    before do
      Octoprint.configure(host: host, api_key: api_key)
    end

    subject { Octoprint::Connection.disconnect }
    it { is_expected.to eq true }
  end

  describe "#connect", :skip, vcr: { cassette_name: "connect" } do
    before do
      Octoprint.configure(host: host, api_key: api_key)
    end

    subject { Octoprint::Connection.connect }
    it { is_expected.to eq true }
  end

  describe "#fake_ack", :skip, vcr: { cassette_name: "fake_ack" } do
    before do
      Octoprint.configure(host: host, api_key: api_key)
    end

    subject { Octoprint::Connection.fake_ack }
    it { is_expected.to eq true }
  end
end
