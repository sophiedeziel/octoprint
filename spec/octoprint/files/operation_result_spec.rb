# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Files::OperationResult do
  let(:local_file) do
    Octoprint::Files::File.new(name: "test.gcode", origin: Octoprint::Location::Local, path: "test.gcode")
  end

  let(:folder) do
    Octoprint::Files::Folder.new(name: "test_folder", origin: Octoprint::Location::Local, path: "test_folder")
  end

  before { Octoprint::Deprecation.reset! }
  after { Octoprint::Deprecation.reset! }

  describe "#initialize" do
    it "creates an operation result with all attributes" do
      result = described_class.new(
        done: true,
        effective_select: false,
        effective_print: true,
        file: local_file,
        folder: folder
      )

      expect(result.done).to be true
      expect(result.effective_select).to be false
      expect(result.effective_print).to be true
      expect(result.file).to eq(local_file)
      expect(result.folder).to eq(folder)
    end

    it "handles optional attributes" do
      result = described_class.new(done: false)

      expect(result.done).to be false
      expect(result.effective_select).to be_nil
      expect(result.effective_print).to be_nil
      expect(result.file).to be_nil
      expect(result.folder).to be_nil
    end
  end

  describe ".deserialize" do
    it "deserializes an upload result with a nested file" do
      data = {
        done: true,
        effective_select: false,
        effective_print: false,
        file: {
          name: "test_file.gcode",
          origin: "local",
          path: "test_file.gcode",
          refs: {
            download: "http://octoprint.local/downloads/files/local/test_file.gcode",
            resource: "http://octoprint.local/api/files/local/test_file.gcode"
          }
        }
      }

      result = described_class.deserialize(data)

      expect(result.done).to be true
      expect(result.effective_select).to be false
      expect(result.effective_print).to be false
      expect(result.file).to be_a(Octoprint::Files::File)
      expect(result.file.name).to eq("test_file.gcode")
      expect(result.file.origin).to eq(Octoprint::Location::Local)
      expect(result.file.refs).to be_a(Octoprint::Files::Refs)
      expect(result.file.refs.resource).to eq("http://octoprint.local/api/files/local/test_file.gcode")
      expect(result.folder).to be_nil
    end

    it "deserializes a printer file origin to Location::Printer" do
      data = { done: false, file: { name: "/test_f~1.gco", origin: "printer", path: "/test_f~1.gco" } }

      result = described_class.deserialize(data)

      expect(result.file.origin).to eq(Octoprint::Location::Printer)
    end

    it "deserializes operation result with nested folder" do
      data = {
        done: true,
        folder: {
          name: "uploaded_folder",
          origin: "local",
          path: "uploaded_folder"
        }
      }

      result = described_class.deserialize(data)

      expect(result.done).to be true
      expect(result.folder).to be_a(Octoprint::Files::Folder)
      expect(result.folder.name).to eq("uploaded_folder")
      expect(result.file).to be_nil
    end

    it "handles a result without file or folder" do
      result = described_class.deserialize({ done: false, effective_select: nil, effective_print: nil })

      expect(result.done).to be false
      expect(result.file).to be_nil
      expect(result.folder).to be_nil
    end
  end

  describe "#files (deprecated)" do
    it "returns the uploaded file keyed by its origin" do
      result = described_class.new(done: true, file: local_file)

      files = nil
      expect { files = result.files }.to output(/deprecated/).to_stderr

      expect(files).to eq({ Octoprint::Location::Local => local_file })
    end

    it "keys a printer file by Location::Printer" do
      printer_file = Octoprint::Files::File.new(name: "A.GCO", origin: Octoprint::Location::Printer, path: "A.GCO")
      result = described_class.new(done: true, file: printer_file)

      expect { expect(result.files).to eq({ Octoprint::Location::Printer => printer_file }) }
        .to output.to_stderr
    end

    it "returns nil for a folder result" do
      result = described_class.new(done: true, folder: folder)

      expect { expect(result.files).to be_nil }.to output.to_stderr
    end

    it "prints the deprecation warning" do
      result = described_class.new(done: true, file: local_file)

      expect { result.files }
        .to output("[octoprint] Files::OperationResult#files is deprecated: use #file instead\n").to_stderr
    end

    it "warns only once" do
      result = described_class.new(done: true, file: local_file)

      expect { result.files }.to output(/deprecated/).to_stderr
      expect { result.files }.not_to output.to_stderr
      expect { described_class.new(done: true, folder: folder).files }.not_to output.to_stderr
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
        :done, :effective_select, :effective_print, :file, :folder
      )
    end

    it "doesn't have a files auto_attr" do
      expect(described_class.auto_attrs).not_to include(:files)
    end
  end
end
