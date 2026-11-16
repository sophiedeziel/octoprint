# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Printer::Storage do
  include_context "with default Octoprint config"

  describe "inheritance and configuration" do
    it "inherits from BaseResource" do
      expect(described_class).to be < Octoprint::BaseResource
    end

    it "has correct resource path" do
      expect(described_class.instance_variable_get(:@path)).to eq("/api/printer/storage")
    end

    it "includes AutoInitializable and Deserializable" do
      expect(described_class.new).to be_a(Octoprint::AutoInitializable)
      expect(described_class.new).to be_a(Octoprint::Deserializable)
    end

    it "has a legacy converter" do
      expect(described_class.legacy_converter).to be(Octoprint::Printer::Storage::Legacy)
    end
  end

  describe ".get" do
    let(:storage) { described_class.new(ready: true) }

    before do
      allow(described_class).to receive(:fetch_resource).and_return(storage)
    end

    it "fetches the resource with no arguments" do
      described_class.get

      expect(described_class).to have_received(:fetch_resource).with(no_args)
    end

    it "returns the storage state" do
      expect(described_class.get).to be(storage)
    end
  end

  describe ".deserialize" do
    it "deserializes the ready flag" do
      expect(described_class.deserialize({ ready: true }).ready).to be(true)
      expect(described_class.deserialize({ ready: false }).ready).to be(false)
    end

    it "has no extra fields for a known response" do
      expect(described_class.deserialize({ ready: true }).extra).to be_nil
    end

    it "collects unknown fields in extra" do
      storage = described_class.deserialize({ ready: true, size: 1024 })

      expect(storage.extra).to eq({ size: 1024 })
    end
  end

  describe ".issue_command" do
    before do
      allow(described_class).to receive(:post).and_return(true)
    end

    it "posts with the correct command" do
      described_class.issue_command(command: "refresh")

      expect(described_class).to have_received(:post).with(params: { command: "refresh" })
    end

    it "returns the post result" do
      expect(described_class.issue_command(command: "refresh")).to be(true)
    end
  end

  %w[init refresh release].each do |command|
    describe ".#{command}" do
      before do
        allow(described_class).to receive(:issue_command).and_return(true)
      end

      it "delegates to issue_command with #{command}" do
        expect(described_class.public_send(command)).to be(true)

        expect(described_class).to have_received(:issue_command).with(command: command)
      end
    end
  end

  describe "requests sent to the server" do
    let(:client) { Octoprint::Client.new(host: "http://test.local", api_key: "key", api_version: api_version) }

    before do
      allow(client).to receive(:request).with("/api/printer/storage", http_method: :get).and_return(ready: true)
      allow(client).to receive(:request).with("/api/printer/sd", http_method: :get).and_return(ready: true)
      allow(client).to receive(:request).with(%r{\A/api/printer/(storage|sd)\z}, hash_including(http_method: :post))
                                        .and_return(true)
    end

    around { |example| client.use { example.run } }

    context "with the 1.11 API" do
      let(:api_version) { "1.11" }

      it "gets the state from /api/printer/sd" do
        expect(described_class.get.ready).to be(true)

        expect(client).to have_received(:request).with("/api/printer/sd", http_method: :get)
      end

      it "posts commands to /api/printer/sd" do
        expect(described_class.init).to be(true)

        expect(client).to have_received(:request)
          .with("/api/printer/sd", http_method: :post, body: { command: "init" }, headers: {}, options: {})
      end
    end

    context "with the 2.0 API" do
      let(:api_version) { "2.0" }

      it "gets the state from /api/printer/storage" do
        expect(described_class.get.ready).to be(true)

        expect(client).to have_received(:request).with("/api/printer/storage", http_method: :get)
      end

      it "posts commands to /api/printer/storage" do
        expect(described_class.release).to be(true)

        expect(client).to have_received(:request)
          .with("/api/printer/storage", http_method: :post, body: { command: "release" }, headers: {}, options: {})
      end
    end
  end
end
