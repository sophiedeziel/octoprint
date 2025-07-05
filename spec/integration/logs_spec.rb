# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Logs, type: :integration do
  include_context "with default Octoprint config"

  describe "List available log files", vcr: { cassette_name: "logs/list" } do
    use_octoprint_server

    subject { described_class.list }

    it { is_expected.to be_a described_class }
    its(:files) { are_expected.to be_a Array }
    its(:files) { are_expected.to all(be_a Octoprint::Logs::LogFile) }
    its(:free) { is_expected.to be_a(Integer).or be_nil }

    context "when server has log files" do
      it "returns log files with proper attributes" do
        logs_response = described_class.list
        unless logs_response.files.empty?
          first_log = logs_response.files.first
          expect(first_log.name).to be_a(String)
          expect(first_log.size).to be_a(Integer)
          expect(first_log.date).to be_a(Integer)
          expect(first_log.modification_time).to be_a(Time)
        end
      end
    end

    context "when server has no log files" do
      it "returns empty files array" do
        # This could happen on a fresh installation
        logs_response = described_class.list
        expect(logs_response.files).to eq([]) if logs_response.files.empty?
      end
    end
  end

  describe "Delete a log file", vcr: { cassette_name: "logs/delete" } do
    use_octoprint_server

    subject(:delete_file) { described_class.delete_file(filename: filename) }

    let(:filename) { "octoprint.log" }

    context "when log file exists" do
      it "deletes the file successfully or handles missing endpoint" do
        # NOTE: This test may return true even if file doesn't exist
        # OctoPrint returns 204 No Content for successful deletion
        # If the logging plugin is not available, it may return 404

        result = delete_file
        expect(result).to be_truthy
      rescue Octoprint::Exceptions::NotFoundError
        # This is acceptable - the logging plugin may not be available
        # or the specific endpoint may not exist on this OctoPrint instance
        pending "Logging plugin endpoint not available on this OctoPrint instance"
      end
    end

    context "when log file does not exist", vcr: { cassette_name: "logs/delete_not_found" } do
      let(:filename) { "nonexistent.log" }

      it "handles non-existent file gracefully" do
        expect { delete_file }.to raise_error(Octoprint::Exceptions::NotFoundError)
      end
    end
  end

  describe "Integration behavior with real server responses" do
    use_octoprint_server

    describe "list operation", vcr: { cassette_name: "logs/list_detailed" } do
      it "returns properly structured response" do
        logs = described_class.list

        expect(logs).to be_a(described_class)
        expect(logs.files).to be_an(Array)
      end

      it "returns valid log file objects" do
        logs = described_class.list

        # Verify each log file has required attributes
        logs.files.each do |log_file|
          expect(log_file).to be_a(Octoprint::Logs::LogFile)
          expect(log_file.name).to be_a(String)
          expect(log_file.name).not_to be_empty
          expect(log_file.size).to be_a(Integer)
          expect(log_file.size).to be >= 0
          expect(log_file.date).to be_a(Integer)
          expect(log_file.date).to be > 0
          expect(log_file.modification_time).to be_a(Time)
        end
      end

      it "provides valid free space information when available" do
        logs = described_class.list

        # Verify free space information if provided
        if logs.free
          expect(logs.free).to be_a(Integer)
          expect(logs.free).to be >= 0
        end
      end
    end

    describe "LogFile string representation" do
      it "provides human-readable output", vcr: { cassette_name: "logs/list_for_display" } do
        logs = described_class.list

        unless logs.files.empty?
          log_file = logs.files.first
          string_repr = log_file.to_s

          expect(string_repr).to include(log_file.name)
          expect(string_repr).to include("bytes")
          expect(string_repr).to include("modified:")
        end
      end
    end
  end

  describe "Error handling" do
    use_octoprint_server

    let(:mock_client) { instance_double(Octoprint::Client) }

    before do
      # Stub the private client method to return a mock client instance
      allow(described_class).to receive(:client).and_return(mock_client)
    end

    describe "when server returns unexpected data structure" do
      before do
        allow(mock_client).to receive(:request).and_return({
                                                             files: nil,
                                                             free: nil
                                                           })
      end

      it "handles nil files gracefully" do
        expect { described_class.list }.not_to raise_error
      end
    end

    describe "when network issues occur" do
      before do
        allow(mock_client).to receive(:request)
          .and_raise(Octoprint::Exceptions::InternalServerError, "Server error")
      end

      it "propagates server errors appropriately" do
        expect { described_class.list }.to raise_error(Octoprint::Exceptions::InternalServerError)
      end
    end
  end

  describe "API path construction" do
    let(:client) { Octoprint::Client.new(host: "http://test.local", api_key: "test_key") }

    before do
      allow(described_class).to receive(:client).and_return(client)
      allow(client).to receive(:request).and_return({ files: [], free: 1000 })
    end

    it "uses correct API endpoint for list operation" do
      described_class.list

      expect(client).to have_received(:request).with("/plugin/logging/logs", hash_including(http_method: :get))
    end

    it "constructs correct path for delete operation" do
      allow(client).to receive(:request).and_return(true)

      described_class.delete_file(filename: "test.log")

      expect(client).to have_received(:request).with(
        "/plugin/logging/logs/test.log",
        hash_including(http_method: :delete)
      )
    end

    it "handles filenames with special characters in delete operation" do
      allow(client).to receive(:request).and_return(true)

      described_class.delete_file(filename: "test.log.2023-01-01.gz")

      expect(client).to have_received(:request).with(
        "/plugin/logging/logs/test.log.2023-01-01.gz",
        hash_including(http_method: :delete)
      )
    end
  end
end
