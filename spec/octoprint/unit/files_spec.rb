# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Files do
  include_context "with default Octoprint config"

  let(:mock_client) { instance_double(Octoprint::Client) }

  before do
    allow(Octoprint).to receive(:client).and_return(T.unsafe(mock_client))
  end

  describe "#initialize" do
    let(:file_data) do
      [
        { name: "test1.gcode", origin: "local", path: "test1.gcode" },
        { name: "test2.gcode", origin: "local", path: "test2.gcode" }
      ]
    end

    it "creates Files::File objects from file data" do
      allow(Octoprint::Files::File).to receive(:deserialize).with(file_data[0]).and_return("file1")
      allow(Octoprint::Files::File).to receive(:deserialize).with(file_data[1]).and_return("file2")

      files = described_class.new(files: file_data, free: 1000, total: 3000)

      expect(files.files).to eq(%w[file1 file2])
      expect(files.free).to eq(1000)
      expect(files.total).to eq(3000)
    end

    it "handles optional free and total parameters" do
      allow(Octoprint::Files::File).to receive(:deserialize).and_return("file")

      files = described_class.new(files: file_data)

      expect(files.free).to be_nil
      expect(files.total).to be_nil
    end
  end

  describe ".list" do
    let(:mock_response) { { files: [], free: 1000, total: 3000 } }

    before do
      allow(described_class).to receive(:fetch_resource).and_return(mock_response)
    end

    context "with default parameters" do
      it "fetches files from local location" do
        described_class.list
        expect(described_class).to have_received(:fetch_resource).with("local", options: {})
      end
    end

    context "with SD card location" do
      it "fetches files from SD card location" do
        described_class.list(location: Octoprint::Location::SDCard)
        expect(described_class).to have_received(:fetch_resource).with("sdcard", options: {})
      end
    end

    context "with options" do
      it "passes options to fetch_resource" do
        options = { recursive: true, force: true }
        described_class.list(options: options)
        expect(described_class).to have_received(:fetch_resource).with("local", options: options)
      end
    end
  end

  describe ".get" do
    let(:file_response) { { name: "test.gcode", origin: "local", path: "test.gcode" } }
    let(:mock_file) { instance_double(Octoprint::Files::File) }

    before do
      allow(described_class).to receive(:fetch_resource).and_return(file_response)
      allow(Octoprint::Files::File).to receive(:deserialize).with(file_response).and_return(mock_file)
    end

    context "with default parameters" do
      it "fetches file from local location" do
        result = described_class.get(filename: "test.gcode")
        expect(described_class).to have_received(:fetch_resource).with(
          "local/test.gcode", deserialize: false, options: {}
        )
        expect(result).to eq(mock_file)
      end
    end

    context "with SD card location" do
      it "fetches file from SD card location" do
        described_class.get(filename: "TEST.GCO", location: Octoprint::Location::SDCard)
        expect(described_class).to have_received(:fetch_resource).with(
          "sdcard/TEST.GCO", deserialize: false, options: {}
        )
      end
    end

    context "with options" do
      it "passes options to fetch_resource" do
        options = { recursive: true }
        described_class.get(filename: "test.gcode", options: options)
        expect(described_class).to have_received(:fetch_resource).with(
          "local/test.gcode", deserialize: false, options: options
        )
      end
    end
  end

  describe ".upload" do
    let(:file_path) { "/path/to/test.gcode" }
    let(:upload_io) { instance_double(Faraday::UploadIO) }
    let(:mock_response) { { done: true, files: {} } }
    let(:mock_result) { instance_double(Octoprint::Files::OperationResult) }

    before do
      allow(Faraday::UploadIO).to receive(:new).with(file_path, "application/octet-stream").and_return(upload_io)
      allow(described_class).to receive(:post).and_return(mock_response)
      allow(Octoprint::Files::OperationResult).to receive(:deserialize).with(mock_response).and_return(mock_result)
    end

    context "with default parameters" do
      it "uploads to local location with minimal parameters" do
        result = described_class.upload(file_path)

        expect(described_class).to have_received(:post).with(
          path: "/api/files/local",
          params: { file: upload_io }
        )
        expect(result).to eq(mock_result)
      end
    end

    context "with SD card location" do
      it "uploads to SD card location" do
        described_class.upload(file_path, location: Octoprint::Location::SDCard)

        expect(described_class).to have_received(:post).with(
          path: "/api/files/sdcard",
          params: { file: upload_io }
        )
      end
    end

    context "with options" do
      it "includes all options in params" do
        options = {
          path: "subfolder",
          select: true,
          print: false,
          userdata: '{"key": "value"}'
        }

        described_class.upload(file_path, options: options)

        expect(described_class).to have_received(:post).with(
          path: "/api/files/local",
          params: {
            file: upload_io,
            path: "subfolder",
            select: true,
            print: false,
            userdata: '{"key": "value"}'
          }
        )
      end

      it "excludes nil options from params" do
        options = { path: "subfolder", select: nil, print: true }

        described_class.upload(file_path, options: options)

        expect(described_class).to have_received(:post).with(
          path: "/api/files/local",
          params: {
            file: upload_io,
            path: "subfolder",
            print: true
          }
        )
      end
    end
  end

  describe ".create_folder" do
    let(:mock_response) { { done: true, folder: {} } }
    let(:mock_result) { instance_double(Octoprint::Files::OperationResult) }

    before do
      allow(described_class).to receive(:post).and_return(mock_response)
      allow(Octoprint::Files::OperationResult).to receive(:deserialize).with(mock_response).and_return(mock_result)
    end

    context "with default parameters" do
      it "creates folder in local location" do
        result = described_class.create_folder(foldername: "test_folder")

        expect(described_class).to have_received(:post).with(
          path: "/api/files/local",
          params: { foldername: "test_folder" },
          options: { force_multipart: true }
        )
        expect(result).to eq(mock_result)
      end
    end

    context "with SD card location" do
      it "creates folder in SD card location" do
        described_class.create_folder(foldername: "test_folder", location: Octoprint::Location::SDCard)

        expect(described_class).to have_received(:post).with(
          path: "/api/files/sdcard",
          params: { foldername: "test_folder" },
          options: { force_multipart: true }
        )
      end
    end

    context "with path parameter" do
      it "includes path in params" do
        described_class.create_folder(foldername: "test_folder", path: "/parent")

        expect(described_class).to have_received(:post).with(
          path: "/api/files/local",
          params: { foldername: "test_folder", path: "/parent" },
          options: { force_multipart: true }
        )
      end

      it "excludes nil path from params" do
        described_class.create_folder(foldername: "test_folder", path: nil)

        expect(described_class).to have_received(:post).with(
          path: "/api/files/local",
          params: { foldername: "test_folder" },
          options: { force_multipart: true }
        )
      end
    end
  end

  describe ".issue_command" do
    before do
      allow(described_class).to receive(:post).and_return(true)
    end

    it "issues command to specified file" do
      described_class.issue_command(
        filename: "test.gcode",
        command: "select",
        location: Octoprint::Location::Local,
        options: { print: true }
      )

      expect(described_class).to have_received(:post).with(
        path: "/api/files/local/test.gcode",
        params: { command: "select", print: true }
      )
    end

    it "works with SD card location" do
      described_class.issue_command(
        filename: "TEST.GCO",
        command: "unselect",
        location: Octoprint::Location::SDCard,
        options: {}
      )

      expect(described_class).to have_received(:post).with(
        path: "/api/files/sdcard/TEST.GCO",
        params: { command: "unselect" }
      )
    end
  end

  describe ".select" do
    before do
      allow(described_class).to receive(:issue_command).and_return(true)
    end

    context "without print parameter" do
      it "calls issue_command with select command" do
        described_class.select(filename: "test.gcode")

        expect(described_class).to have_received(:issue_command).with(
          filename: "test.gcode",
          command: "select",
          location: Octoprint::Location::Local,
          options: {}
        )
      end
    end

    context "with print parameter" do
      it "includes print option when true" do
        described_class.select(filename: "test.gcode", print: true)

        expect(described_class).to have_received(:issue_command).with(
          filename: "test.gcode",
          command: "select",
          location: Octoprint::Location::Local,
          options: { print: true }
        )
      end

      it "includes print option when false" do
        described_class.select(filename: "test.gcode", print: false)

        expect(described_class).to have_received(:issue_command).with(
          filename: "test.gcode",
          command: "select",
          location: Octoprint::Location::Local,
          options: { print: false }
        )
      end
    end
  end

  describe ".unselect" do
    before do
      allow(described_class).to receive(:issue_command).and_return(true)
    end

    it "calls issue_command with unselect command" do
      described_class.unselect(filename: "test.gcode", location: Octoprint::Location::SDCard)

      expect(described_class).to have_received(:issue_command).with(
        filename: "test.gcode",
        command: "unselect",
        location: Octoprint::Location::SDCard,
        options: {}
      )
    end
  end

  describe ".slice" do
    before do
      allow(described_class).to receive(:issue_command).and_return(true)
    end

    context "with default parameters" do
      it "calls issue_command with slice command" do
        described_class.slice(filename: "model.stl")

        expect(described_class).to have_received(:issue_command).with(
          filename: "model.stl",
          command: "slice",
          location: Octoprint::Location::Local,
          options: {}
        )
      end
    end

    context "with print parameter" do
      it "includes print option" do
        described_class.slice(filename: "model.stl", print: true)

        expect(described_class).to have_received(:issue_command).with(
          filename: "model.stl",
          command: "slice",
          location: Octoprint::Location::Local,
          options: { print: true }
        )
      end
    end

    context "with profile parameter" do
      it "merges profile options" do
        profile = { slicer: "cura", setting1: "value1" }
        described_class.slice(filename: "model.stl", profile: profile)

        expect(described_class).to have_received(:issue_command).with(
          filename: "model.stl",
          command: "slice",
          location: Octoprint::Location::Local,
          options: { slicer: "cura", setting1: "value1" }
        )
      end
    end

    context "with print and profile parameters" do
      it "includes both print and profile options" do
        profile = { slicer: "cura" }
        described_class.slice(filename: "model.stl", print: true, profile: profile)

        expect(described_class).to have_received(:issue_command).with(
          filename: "model.stl",
          command: "slice",
          location: Octoprint::Location::Local,
          options: { print: true, slicer: "cura" }
        )
      end
    end
  end

  describe ".copy" do
    before do
      allow(described_class).to receive(:issue_command).and_return({ status: "created" })
    end

    it "calls issue_command with copy command and destination" do
      described_class.copy(filename: "source.gcode", destination: "backup.gcode")

      expect(described_class).to have_received(:issue_command).with(
        filename: "source.gcode",
        command: "copy",
        location: Octoprint::Location::Local,
        options: { destination: "backup.gcode" }
      )
    end

    it "works with different location" do
      described_class.copy(
        filename: "source.gcode",
        destination: "backup.gcode",
        location: Octoprint::Location::SDCard
      )

      expect(described_class).to have_received(:issue_command).with(
        filename: "source.gcode",
        command: "copy",
        location: Octoprint::Location::SDCard,
        options: { destination: "backup.gcode" }
      )
    end
  end

  describe ".move" do
    before do
      allow(described_class).to receive(:issue_command).and_return({ status: "created" })
    end

    it "calls issue_command with move command and destination" do
      described_class.move(filename: "old_name.gcode", destination: "new_name.gcode")

      expect(described_class).to have_received(:issue_command).with(
        filename: "old_name.gcode",
        command: "move",
        location: Octoprint::Location::Local,
        options: { destination: "new_name.gcode" }
      )
    end
  end

  describe ".delete_file" do
    before do
      allow(described_class).to receive(:delete).and_return(true)
    end

    it "calls delete with correct path for local location" do
      described_class.delete_file(filename: "test.gcode")

      expect(described_class).to have_received(:delete).with(path: "/api/files/local/test.gcode")
    end

    it "calls delete with correct path for SD card location" do
      described_class.delete_file(filename: "TEST.GCO", location: Octoprint::Location::SDCard)

      expect(described_class).to have_received(:delete).with(path: "/api/files/sdcard/TEST.GCO")
    end
  end

  describe "inheritance" do
    it "inherits from BaseResource" do
      expect(described_class).to be < Octoprint::BaseResource
    end

    it "has correct resource path" do
      expect(described_class.instance_variable_get(:@path)).to eq("/api/files")
    end
  end
end