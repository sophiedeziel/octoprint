# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Files::Folder do
  describe "#initialize" do
    it "creates a folder with all required attributes" do
      refs = Octoprint::Files::Refs.new(
        resource: "http://example.com/api/files/local/test_folder",
        download: "http://example.com/downloads/files/local/test_folder"
      )

      folder = described_class.new(
        name: "test_folder",
        display_name: "Test Folder",
        origin: Octoprint::Location::Local,
        path: "test_folder",
        refs: refs
      )

      expect(folder.name).to eq("test_folder")
      expect(folder.display_name).to eq("Test Folder")
      expect(folder.origin).to eq(Octoprint::Location::Local)
      expect(folder.path).to eq("test_folder")
      expect(folder.refs).to eq(refs)
    end

    it "handles optional attributes" do
      folder = described_class.new(
        name: "simple_folder",
        origin: Octoprint::Location::Local,
        path: "simple_folder"
      )

      expect(folder.name).to eq("simple_folder")
      expect(folder.display_name).to be_nil
      expect(folder.refs).to be_nil
    end
  end

  describe ".deserialize" do
    it "deserializes folder data with nested refs" do
      data = {
        name: "documents",
        display: "Documents Folder",
        origin: "local",
        path: "documents",
        refs: {
          resource: "http://example.com/api/files/local/documents",
          download: "http://example.com/downloads/files/local/documents"
        }
      }

      folder = described_class.deserialize(data)

      expect(folder.name).to eq("documents")
      expect(folder.display_name).to eq("Documents Folder")
      expect(folder.origin).to eq("local")
      expect(folder.path).to eq("documents")
      expect(folder.refs).to be_a(Octoprint::Files::Refs)
      expect(folder.refs.resource).to eq("http://example.com/api/files/local/documents")
    end

    it "handles missing refs" do
      data = {
        name: "empty_folder",
        origin: "sdcard",
        path: "empty_folder"
      }

      folder = described_class.deserialize(data)

      expect(folder.name).to eq("empty_folder")
      expect(folder.origin).to eq("sdcard")
      expect(folder.refs).to be_nil
    end

    it "renames display key to display_name" do
      data = {
        name: "test",
        display: "Test Display Name",
        origin: "local",
        path: "test"
      }

      folder = described_class.deserialize(data)

      expect(folder.display_name).to eq("Test Display Name")
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
        :name, :display_name, :origin, :path, :refs
      )
    end
  end
end
