# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Files do
  include_context "with default Octoprint config"

  describe "#initialize" do
    let(:file_data) do
      [
        { name: "test1.gcode", origin: "local", path: "test1.gcode" },
        { name: "test2.gcode", origin: "local", path: "test2.gcode" }
      ]
    end

    it "creates Files::File objects from file data" do
      files = described_class.new(files: file_data, free: 1000, total: 3000)

      expect(files.files).to be_an(Array)
      expect(files.files.length).to eq(2)
      expect(files.files.first).to be_a(Octoprint::Files::File)
      expect(files.files.first.name).to eq("test1.gcode")
      expect(files.files.last.name).to eq("test2.gcode")
      expect(files.free).to eq(1000)
      expect(files.total).to eq(3000)
    end

    it "handles optional free and total parameters" do
      files = described_class.new(files: file_data)

      expect(files.free).to be_nil
      expect(files.total).to be_nil
    end
  end

  describe "class method parameter validation" do
    it "validates location parameter types" do
      expect do
        described_class.upload("test.gcode", location: "invalid")
      end.to raise_error(TypeError, /Parameter 'location': Expected type Octoprint::Location, got type/)
    end
  end

  describe "inheritance and configuration" do
    it "inherits from BaseResource" do
      expect(described_class).to be < Octoprint::BaseResource
    end

    it "has correct resource path" do
      expect(described_class.instance_variable_get(:@path)).to eq("/api/files")
    end
  end

  describe "method signatures and behavior patterns" do
    let(:client) { Octoprint::Client.new(host: "http://test.local", api_key: "test_key") }

    before do
      allow(described_class).to receive(:client).and_return(client)
      allow(client).to receive(:request).and_return({})
    end

    it "constructs correct paths for issue_command" do
      allow(described_class).to receive(:post).and_return(true)

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

    it "constructs correct paths for delete_file" do
      allow(described_class).to receive(:delete).and_return(true)

      described_class.delete_file(filename: "test.gcode")

      expect(described_class).to have_received(:delete).with(path: "/api/files/local/test.gcode")
    end

    it "handles SD card location paths correctly" do
      allow(described_class).to receive(:delete).and_return(true)

      described_class.delete_file(filename: "TEST.GCO", location: Octoprint::Location::SDCard)

      expect(described_class).to have_received(:delete).with(path: "/api/files/sdcard/TEST.GCO")
    end
  end

  describe "convenience method delegation" do
    before do
      allow(described_class).to receive(:issue_command).and_return(true)
    end

    it "select delegates to issue_command with correct parameters" do
      described_class.select(filename: "test.gcode", print: true)

      expect(described_class).to have_received(:issue_command).with(
        filename: "test.gcode",
        command: "select",
        location: Octoprint::Location::Local,
        options: { print: true }
      )
    end

    it "unselect delegates to issue_command" do
      described_class.unselect(filename: "test.gcode")

      expect(described_class).to have_received(:issue_command).with(
        filename: "test.gcode",
        command: "unselect",
        location: Octoprint::Location::Local,
        options: {}
      )
    end

    it "copy delegates to issue_command with destination" do
      described_class.copy(filename: "source.gcode", destination: "backup.gcode")

      expect(described_class).to have_received(:issue_command).with(
        filename: "source.gcode",
        command: "copy",
        location: Octoprint::Location::Local,
        options: { destination: "backup.gcode" }
      )
    end

    it "move delegates to issue_command with destination" do
      described_class.move(filename: "old.gcode", destination: "new.gcode")

      expect(described_class).to have_received(:issue_command).with(
        filename: "old.gcode",
        command: "move",
        location: Octoprint::Location::Local,
        options: { destination: "new.gcode" }
      )
    end
  end

  describe "slice method behavior" do
    before do
      allow(described_class).to receive(:issue_command).and_return(true)
    end

    it "merges profile options correctly" do
      profile = { slicer: "cura", setting1: "value1" }
      described_class.slice(filename: "model.stl", print: true, profile: profile)

      expect(described_class).to have_received(:issue_command).with(
        filename: "model.stl",
        command: "slice",
        location: Octoprint::Location::Local,
        options: { print: true, slicer: "cura", setting1: "value1" }
      )
    end

    it "handles nil profile parameter" do
      described_class.slice(filename: "model.stl", print: false, profile: nil)

      expect(described_class).to have_received(:issue_command).with(
        filename: "model.stl",
        command: "slice",
        location: Octoprint::Location::Local,
        options: { print: false }
      )
    end
  end

  describe "edge cases in method parameters" do
    before do
      allow(described_class).to receive(:issue_command).and_return(true)
    end

    it "handles print parameter as false in select method" do
      described_class.select(filename: "test.gcode", print: false)

      expect(described_class).to have_received(:issue_command).with(
        filename: "test.gcode",
        command: "select",
        location: Octoprint::Location::Local,
        options: { print: false }
      )
    end

    it "handles print parameter as nil explicitly in slice method" do
      described_class.slice(filename: "model.stl", print: nil)

      expect(described_class).to have_received(:issue_command).with(
        filename: "model.stl",
        command: "slice",
        location: Octoprint::Location::Local,
        options: {}
      )
    end

    it "covers slice method with profile parameter merging" do
      profile = { slicer: "cura", speed: "fast" }
      described_class.slice(filename: "model.stl", profile: profile)

      expect(described_class).to have_received(:issue_command).with(
        filename: "model.stl",
        command: "slice",
        location: Octoprint::Location::Local,
        options: { slicer: "cura", speed: "fast" }
      )
    end

    it "covers slice method with specific parameter combinations" do
      described_class.slice(
        filename: "test.stl",
        location: Octoprint::Location::SDCard,
        print: false,
        profile: { setting: "value" }
      )

      expect(described_class).to have_received(:issue_command).with(
        filename: "test.stl",
        command: "slice",
        location: Octoprint::Location::SDCard,
        options: { print: false, setting: "value" }
      )
    end

    it "covers select method with nil print parameter" do
      described_class.select(filename: "test.gcode", print: nil)

      expect(described_class).to have_received(:issue_command).with(
        filename: "test.gcode",
        command: "select",
        location: Octoprint::Location::Local,
        options: {}
      )
    end
  end
end
