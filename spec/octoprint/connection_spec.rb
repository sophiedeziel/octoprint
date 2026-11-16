# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Connection do
  let(:api_version) { "2.0" }
  let(:client) { Octoprint::Client.new(host: "http://test.local", api_key: "key", api_version: api_version) }

  before do
    Octoprint::Deprecation.reset!
    allow(client).to receive(:request).and_return(true)
    allow(described_class).to receive(:client).and_return(client)
  end

  def sent_body
    body = nil
    expect(client).to have_received(:request) { |_path, **options| body = options[:body] }
    body
  end

  describe ".connect" do
    it "sends the connector and its parameters" do
      described_class.connect(connector: "serial", parameters: { port: "VIRTUAL", baudrate: 115_200 },
                              printer_profile: "_default", save: false, autoconnect: true)

      expect(sent_body).to eq(command: "connect", connector: "serial",
                              parameters: { port: "VIRTUAL", baudrate: 115_200 },
                              printerProfile: "_default", save: false, autoconnect: true)
    end

    it "uses the serial connector by default" do
      described_class.connect

      expect(sent_body).to eq(command: "connect", connector: "serial")
    end

    context "with the deprecated call style" do
      it "converts the keywords and warns once" do
        expect do
          described_class.connect(port: "VIRTUAL", baudrate: 115_200, printerProfile: "_default")
          described_class.connect(port: "VIRTUAL")
        end.to output(/\A[^\n]*Connection.connect\(port:, baudrate:, printerProfile:\) is deprecated[^\n]*\n\z/)
          .to_stderr

        expect(client).to have_received(:request).with(
          "/api/connection", hash_including(body: { command: "connect", connector: "serial",
                                                    parameters: { port: "VIRTUAL", baudrate: 115_200 },
                                                    printerProfile: "_default" })
        )
      end

      it "accepts a hash argument" do
        expect do
          described_class.connect({ port: "VIRTUAL", save: true, autoconnect: false })
        end.to output(/deprecated/).to_stderr

        expect(sent_body).to eq(command: "connect", connector: "serial", parameters: { port: "VIRTUAL" }, save: true,
                                autoconnect: false)
      end

      it "prefers the new keywords" do
        expect do
          described_class.connect({ port: "COM1", printerProfile: "old", save: true },
                                  parameters: { port: "VIRTUAL" }, printer_profile: "new", save: false)
        end.to output(/deprecated/).to_stderr

        expect(sent_body).to eq(command: "connect", connector: "serial", parameters: { port: "VIRTUAL" },
                                printerProfile: "new", save: false)
      end

      it "rejects unknown keys" do
        expect { described_class.connect(port: "VIRTUAL", banana: 1) }
          .to raise_error(ArgumentError, "unknown keywords: :banana")
        expect(client).not_to have_received(:request)
      end
    end

    context "with the 1.11 API" do
      let(:api_version) { "1.11" }

      it "sends the serial parameters as port and baudrate" do
        described_class.connect(connector: "serial", parameters: { port: "VIRTUAL", baudrate: 115_200 })

        expect(sent_body).to eq(command: "connect", port: "VIRTUAL", baudrate: 115_200)
      end

      it "raises for another connector, without a request" do
        expect { described_class.connect(connector: "klipper", parameters: {}) }
          .to raise_error(Octoprint::Exceptions::UnsupportedFeatureError, /connectors needs the OctoPrint 2.0 API/)
        expect(client).not_to have_received(:request)
      end
    end
  end

  describe ".repair" do
    it "sends repair" do
      described_class.repair

      expect(sent_body).to eq(command: "repair")
    end

    context "with the 1.11 API" do
      let(:api_version) { "1.11" }

      it "sends fake_ack" do
        described_class.repair

        expect(sent_body).to eq(command: "fake_ack")
      end
    end
  end

  describe ".fake_ack" do
    it "repairs and warns once" do
      expect do
        expect(described_class.fake_ack).to be true
        described_class.fake_ack
      end.to output("[octoprint] Connection.fake_ack is deprecated: use Connection.repair\n").to_stderr

      expect(client).to have_received(:request)
        .with("/api/connection", hash_including(body: { command: "repair" })).twice
    end
  end

  describe ".disconnect" do
    it "sends disconnect" do
      described_class.disconnect

      expect(sent_body).to eq(command: "disconnect")
    end
  end
end
