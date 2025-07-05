# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Logs do
  include_context "with default Octoprint config"

  describe "#initialize" do
    let(:log_data) do
      [
        { name: "octoprint.log", size: 1024, date: 1640995200, refs: { resource: "http://test.local/logs/octoprint.log" } },
        { name: "octoprint.log.1", size: 2048, date: 1640908800, refs: { resource: "http://test.local/logs/octoprint.log.1" } }
      ]
    end

    it "creates LogFile objects from log data" do
      logs = described_class.new(files: log_data, free: 1000000)

      expect(logs.files).to be_an(Array)
      expect(logs.files.length).to eq(2)
      expect(logs.files.first).to be_a(Octoprint::Logs::LogFile)
      expect(logs.files.first.name).to eq("octoprint.log")
      expect(logs.files.first.size).to eq(1024)
      expect(logs.files.last.name).to eq("octoprint.log.1")
      expect(logs.free).to eq(1000000)
    end

    it "handles optional free parameter" do
      logs = described_class.new(files: log_data)

      expect(logs.free).to be_nil
    end

    it "handles empty files array" do
      logs = described_class.new(files: [])

      expect(logs.files).to be_an(Array)
      expect(logs.files).to be_empty
    end
  end

  describe "inheritance and configuration" do
    it "inherits from BaseResource" do
      expect(described_class).to be < Octoprint::BaseResource
    end

    it "includes Deserializable" do
      expect(described_class).to include(Octoprint::Deserializable)
    end

    it "includes AutoInitializable" do
      expect(described_class).to include(Octoprint::AutoInitializable)
    end

    it "has correct resource path" do
      expect(described_class.instance_variable_get(:@path)).to eq("/plugin/logging/logs")
    end
  end

  describe "class method behavior" do
    let(:client) { Octoprint::Client.new(host: "http://test.local", api_key: "test_key") }

    before do
      allow(described_class).to receive(:client).and_return(client)
      allow(client).to receive(:request).and_return({})
    end

    describe ".list" do
      it "fetches the resource without parameters" do
        allow(described_class).to receive(:fetch_resource).and_return(described_class.new(files: []))

        described_class.list

        expect(described_class).to have_received(:fetch_resource).with(no_args)
      end
    end

    describe ".delete_file" do
      it "constructs correct path for log file deletion" do
        allow(described_class).to receive(:delete).and_return(true)

        described_class.delete_file(filename: "octoprint.log.1")

        expect(described_class).to have_received(:delete).with(path: "/plugin/logging/logs/octoprint.log.1")
      end

      it "handles filename with special characters" do
        allow(described_class).to receive(:delete).and_return(true)

        described_class.delete_file(filename: "test.log.2023-01-01")

        expect(described_class).to have_received(:delete).with(path: "/plugin/logging/logs/test.log.2023-01-01")
      end

      it "returns the result from delete method" do
        allow(described_class).to receive(:delete).and_return(true)

        result = described_class.delete_file(filename: "octoprint.log")

        expect(result).to be true
      end
    end
  end

  describe "deserialization configuration" do
    it "has proper array configuration for files" do
      config = described_class.deserialize_configuration
      expect(config).not_to be_nil
      expect(config.array_objects[:files]).to eq(Octoprint::Logs::LogFile)
    end
  end
end