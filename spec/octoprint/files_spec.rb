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
      expect(files.usage).to be_nil
    end

    it "accepts the OctoPrint 2.0 storage shape" do
      files = described_class.new(
        files: file_data,
        key: "local",
        name: "Local",
        capabilities: { add_folder: true, thumbnails: true },
        usage: { free: 1000, total: 3000 }
      )

      expect(files.key).to eq("local")
      expect(files.name).to eq("Local")
      expect(files.capabilities).to eq({ add_folder: true, thumbnails: true })
      expect(files.usage).to be_a(Octoprint::Files::Usage)
      expect(files.usage.free).to eq(1000)
      expect(files.usage.total).to eq(3000)
      expect(files.free).to eq(1000)
      expect(files.total).to eq(3000)
    end

    it "builds the usage from the legacy free and total" do
      files = described_class.new(files: file_data, free: 1000, total: 3000)

      expect(files.usage).to be_a(Octoprint::Files::Usage)
      expect(files.usage.free).to eq(1000)
      expect(files.usage.total).to eq(3000)
      expect(files.key).to be_nil
      expect(files.name).to be_nil
      expect(files.capabilities).to be_nil
    end

    it "builds the usage when only free is given" do
      files = described_class.new(files: file_data, free: 1000)

      expect(files.free).to eq(1000)
      expect(files.total).to be_nil
    end

    it "prefers usage over the legacy free and total" do
      files = described_class.new(files: file_data, usage: { free: 1, total: 2 }, free: 1000, total: 3000)

      expect(files.free).to eq(1)
      expect(files.total).to eq(2)
    end

    it "keeps a Files::Usage instance as is" do
      usage = Octoprint::Files::Usage.new(free: 10, total: 20)
      files = described_class.new(files: file_data, usage: usage)

      expect(files.usage).to be(usage)
      expect(files.free).to eq(10)
      expect(files.total).to eq(20)
    end

    it "has no usage when usage is nil" do
      files = described_class.new(files: [], key: "printer", usage: nil)

      expect(files.usage).to be_nil
      expect(files.free).to be_nil
      expect(files.total).to be_nil
    end

    it "ignores unknown attributes" do
      files = described_class.new(files: file_data, key: "local", some_future_field: "value")

      expect(files.key).to eq("local")
      expect(files.files.length).to eq(2)
    end
  end

  describe ".list" do
    it "fetches the storage's files" do
      allow(described_class).to receive(:fetch_resource).and_return(:files)

      expect(described_class.list(location: Octoprint::Location::Printer, options: { recursive: true }))
        .to eq(:files)
      expect(described_class).to have_received(:fetch_resource).with("printer", options: { recursive: true })
    end
  end

  describe ".list_all" do
    let(:storages) do
      {
        local: {
          key: "local",
          name: "Local",
          files: [{ name: "test1.gcode", origin: "local", path: "test1.gcode" }],
          usage: { free: 1000, total: 3000 }
        },
        printer: {
          key: "printer",
          files: [{ name: "TEST.GCO", origin: "printer", path: "TEST.GCO" }]
        }
      }
    end

    before do
      allow(described_class).to receive(:fetch_resource).and_return(storages)
    end

    it "fetches GET /api/files without deserializing it as one storage" do
      described_class.list_all(options: { recursive: true })

      expect(described_class).to have_received(:fetch_resource)
        .with(nil, deserialize: false, options: { recursive: true })
    end

    it "returns a Files per storage, by key" do
      result = described_class.list_all

      expect(result.keys).to eq(%i[local printer])
      expect(result.values).to all(be_a(described_class))
    end

    it "deserializes each storage" do
      result = described_class.list_all

      expect(result[:local].key).to eq("local")
      expect(result[:local].name).to eq("Local")
      expect(result[:local].free).to eq(1000)
      expect(result[:local].files.first.name).to eq("test1.gcode")
      expect(result[:printer].key).to eq("printer")
      expect(result[:printer].usage).to be_nil
      expect(result[:printer].files.first.origin).to eq(Octoprint::Location::Printer)
    end
  end

  describe "copy and move to another storage" do
    let(:client) { Octoprint::Client.new(host: "http://test.local", api_key: "k", api_version: "2.0") }

    before do
      allow(described_class).to receive_messages(client: client, issue_command: true)
      allow(client).to receive(:require_feature!).and_call_original
    end

    %i[copy move].each do |command|
      it "#{command} sends only the destination when the storage is the source's location" do
        described_class.public_send(command, filename: "a.gcode", destination: "b.gcode",
                                             location: Octoprint::Location::Local,
                                             storage: Octoprint::Location::Local)

        expect(client).not_to have_received(:require_feature!)
        expect(described_class).to have_received(:issue_command).with(
          filename: "a.gcode",
          command: command.to_s,
          location: Octoprint::Location::Local,
          options: { destination: "b.gcode" }
        )
      end

      it "#{command} sends the storage when it differs from the location" do
        described_class.public_send(command, filename: "a.gcode", destination: "b.gco",
                                             storage: Octoprint::Location::Printer)

        expect(client).to have_received(:require_feature!).with(:cross_storage_move)
        expect(described_class).to have_received(:issue_command).with(
          filename: "a.gcode",
          command: command.to_s,
          location: Octoprint::Location::Local,
          options: { destination: "b.gco", storage: "printer" }
        )
      end
    end

    context "with the 1.11 API" do
      let(:client) { Octoprint::Client.new(host: "http://test.local", api_key: "k", api_version: "1.11") }

      %i[copy move].each do |command|
        it "#{command} raises UnsupportedFeatureError for another storage" do
          expect do
            described_class.public_send(command, filename: "a.gcode", destination: "b.gco",
                                                 storage: Octoprint::Location::Printer)
          end.to raise_error(Octoprint::Exceptions::UnsupportedFeatureError, /cross_storage_move/)

          expect(described_class).not_to have_received(:issue_command)
        end

        it "#{command} still works within the same storage" do
          described_class.public_send(command, filename: "a.gcode", destination: "b.gcode",
                                               storage: Octoprint::Location::Local)

          expect(described_class).to have_received(:issue_command).with(
            filename: "a.gcode",
            command: command.to_s,
            location: Octoprint::Location::Local,
            options: { destination: "b.gcode" }
          )
        end
      end
    end
  end

  describe ".refresh_thumbnails" do
    let(:client) { Octoprint::Client.new(host: "http://test.local", api_key: "k", api_version: "2.0") }

    before do
      allow(described_class).to receive_messages(client: client, issue_command: true)
    end

    it "refreshes the storage's root folder when no filename is given" do
      described_class.refresh_thumbnails

      expect(described_class).to have_received(:issue_command).with(
        filename: "",
        command: "refresh_thumbnails",
        location: Octoprint::Location::Local,
        options: {}
      )
    end

    it "refreshes a file with the given flags" do
      described_class.refresh_thumbnails(filename: "benchy.gcode", force: true, recursive: false)

      expect(described_class).to have_received(:issue_command).with(
        filename: "benchy.gcode",
        command: "refresh_thumbnails",
        location: Octoprint::Location::Local,
        options: { force: true, recursive: false }
      )
    end

    it "leaves out the flags that aren't given" do
      described_class.refresh_thumbnails(filename: "folder", location: Octoprint::Location::Printer, recursive: true)

      expect(described_class).to have_received(:issue_command).with(
        filename: "folder",
        command: "refresh_thumbnails",
        location: Octoprint::Location::Printer,
        options: { recursive: true }
      )
    end

    context "with the 1.11 API" do
      let(:client) { Octoprint::Client.new(host: "http://test.local", api_key: "k", api_version: "1.11") }

      it "raises UnsupportedFeatureError without sending a request" do
        expect { described_class.refresh_thumbnails(filename: "benchy.gcode") }
          .to raise_error(Octoprint::Exceptions::UnsupportedFeatureError, /refresh_thumbnails/)

        expect(described_class).not_to have_received(:issue_command)
      end
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

    it "handles printer location paths correctly" do
      allow(described_class).to receive(:delete).and_return(true)

      described_class.delete_file(filename: "TEST.GCO", location: Octoprint::Location::Printer)

      expect(described_class).to have_received(:delete).with(path: "/api/files/printer/TEST.GCO")
    end

    it "uses the printer path for the deprecated SDCard location" do
      allow(described_class).to receive(:delete).and_return(true)
      sdcard = Octoprint::Location.const_get(:SDCard)

      described_class.delete_file(filename: "TEST.GCO", location: sdcard)

      expect(described_class).to have_received(:delete).with(path: "/api/files/printer/TEST.GCO")
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
        location: Octoprint::Location::Printer,
        print: false,
        profile: { setting: "value" }
      )

      expect(described_class).to have_received(:issue_command).with(
        filename: "test.stl",
        command: "slice",
        location: Octoprint::Location::Printer,
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
