# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Files::OperationResult do
  describe "#initialize" do
    it "creates an operation result with all attributes" do
      folder = Octoprint::Files::Folder.new(
        name: "test_folder",
        origin: Octoprint::Location::Local,
        path: "test_folder"
      )

      files_hash = {
        Octoprint::Location::Local => Octoprint::Files::File.new(
          name: "test.gcode",
          origin: Octoprint::Location::Local,
          path: "test.gcode"
        )
      }

      result = described_class.new(
        done: true,
        effective_select: false,
        effective_print: true,
        files: files_hash,
        folder: folder
      )

      expect(result.done).to be true
      expect(result.effective_select).to be false
      expect(result.effective_print).to be true
      expect(result.files).to eq(files_hash)
      expect(result.folder).to eq(folder)
    end

    it "handles optional attributes" do
      result = described_class.new(done: false)

      expect(result.done).to be false
      expect(result.effective_select).to be_nil
      expect(result.effective_print).to be_nil
      expect(result.files).to be_nil
      expect(result.folder).to be_nil
    end
  end

  describe ".deserialize" do
    it "deserializes operation result with nested folder" do
      data = {
        done: true,
        effective_select: false,
        effective_print: true,
        folder: {
          name: "uploaded_folder",
          origin: "local",
          path: "uploaded_folder"
        }
      }

      result = described_class.deserialize(data)

      expect(result.done).to be true
      expect(result.effective_select).to be false
      expect(result.effective_print).to be true
      expect(result.folder).to be_a(Octoprint::Files::Folder)
      expect(result.folder.name).to eq("uploaded_folder")
    end

    it "deserializes with files hash transformation" do
      data = {
        done: true,
        files: {
          "local" => {
            name: "test.gcode",
            origin: "local",
            path: "test.gcode"
          },
          "sdcard" => {
            name: "backup.gcode",
            origin: "sdcard",
            path: "backup.gcode"
          }
        }
      }

      result = described_class.deserialize(data)

      expect(result.done).to be true
      expect(result.files).to be_a(Hash)
      expect(result.files.keys).to contain_exactly(
        Octoprint::Location::Local,
        Octoprint::Location::SDCard
      )

      local_file = result.files[Octoprint::Location::Local]
      expect(local_file).to be_a(Octoprint::Files::File)
      expect(local_file.name).to eq("test.gcode")

      sdcard_file = result.files[Octoprint::Location::SDCard]
      expect(sdcard_file).to be_a(Octoprint::Files::File)
      expect(sdcard_file.name).to eq("backup.gcode")
    end

    it "handles missing files hash" do
      data = {
        done: false,
        effective_select: nil,
        effective_print: nil
      }

      result = described_class.deserialize(data)

      expect(result.done).to be false
      expect(result.files).to be_nil
    end

    it "handles empty files hash" do
      data = {
        done: true,
        files: {}
      }

      result = described_class.deserialize(data)

      expect(result.done).to be true
      expect(result.files).to eq({})
    end
  end

  describe "files hash transformation" do
    it "converts string location keys to Location enum values" do
      data = {
        done: true,
        files: {
          "local" => {
            name: "local_file.gcode",
            origin: "local",
            path: "local_file.gcode"
          }
        }
      }

      result = described_class.deserialize(data)

      expect(result.files.keys.first).to eq(Octoprint::Location::Local)
      expect(result.files.keys.first).to be_a(Octoprint::Location)
    end

    it "deserializes file values to Files::File objects" do
      data = {
        done: true,
        files: {
          "local" => {
            name: "test_file.gcode",
            origin: "local",
            path: "test_file.gcode",
            size: 1024
          }
        }
      }

      result = described_class.deserialize(data)
      file = result.files[Octoprint::Location::Local]

      expect(file).to be_a(Octoprint::Files::File)
      expect(file.name).to eq("test_file.gcode")
      expect(file.size).to eq(1024)
    end
  end

  describe "inheritance and modules" do
    it "includes AutoInitializable" do
      expect(described_class.included_modules).to include(Octoprint::AutoInitializable)
    end

    it "includes Deserializable" do
      expect(described_class.included_modules).to include(Octoprint::Deserializable)
    end

    it "has auto_attrs defined" do
      expect(described_class.auto_attrs).to include(
        :done, :effective_select, :effective_print, :files, :folder
      )
    end
  end
end
