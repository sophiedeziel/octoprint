# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Files::Refs do
  describe "#initialize" do
    it "creates refs with all attributes" do
      refs = described_class.new(
        resource: "http://example.com/api/files/local/test.gcode",
        download: "http://example.com/downloads/files/local/test.gcode",
        model: "http://example.com/models/test.stl"
      )

      expect(refs.resource).to eq("http://example.com/api/files/local/test.gcode")
      expect(refs.download).to eq("http://example.com/downloads/files/local/test.gcode")
      expect(refs.model).to eq("http://example.com/models/test.stl")
    end

    it "handles optional attributes" do
      refs = described_class.new(
        resource: "http://example.com/api/files/local/minimal.gcode"
      )

      expect(refs.resource).to eq("http://example.com/api/files/local/minimal.gcode")
      expect(refs.download).to be_nil
      expect(refs.model).to be_nil
    end

    it "can be created with no attributes" do
      refs = described_class.new

      expect(refs.resource).to be_nil
      expect(refs.download).to be_nil
      expect(refs.model).to be_nil
    end
  end

  describe "attribute types" do
    it "accepts string values for all attributes" do
      refs = described_class.new(
        resource: "resource_url",
        download: "download_url",
        model: "model_url"
      )

      expect(refs.resource).to be_a(String)
      expect(refs.download).to be_a(String)
      expect(refs.model).to be_a(String)
    end
  end

  describe "real-world usage examples" do
    it "handles typical OctoPrint file refs" do
      refs = described_class.new(
        resource: "http://octoprint.local/api/files/local/benchy.gcode",
        download: "http://octoprint.local/downloads/files/local/benchy.gcode"
      )

      expect(refs.resource).to include("/api/files/")
      expect(refs.download).to include("/downloads/files/")
    end

    it "handles SD card file refs" do
      refs = described_class.new(
        resource: "http://octoprint.local/api/files/sdcard/PRINT~1.GCO",
        download: "http://octoprint.local/downloads/files/sdcard/PRINT~1.GCO"
      )

      expect(refs.resource).to include("/sdcard/")
      expect(refs.download).to include("/sdcard/")
    end

    it "handles model refs for STL files" do
      refs = described_class.new(
        resource: "http://octoprint.local/api/files/local/model.stl",
        download: "http://octoprint.local/downloads/files/local/model.stl",
        model: "http://octoprint.local/models/model.stl"
      )

      expect(refs.model).to include("/models/")
      expect(refs.model).to end_with(".stl")
    end
  end

  describe "inheritance and modules" do
    it "includes AutoInitializable" do
      expect(described_class.included_modules).to include(Octoprint::AutoInitializable)
    end

    it "has auto_attrs defined" do
      expect(described_class.auto_attrs).to include(
        :resource, :download, :model
      )
    end
  end

  describe "equality and comparison" do
    it "has attributes that can be compared" do
      refs1 = described_class.new(
        resource: "http://example.com/api/test",
        download: "http://example.com/download/test"
      )

      refs2 = described_class.new(
        resource: "http://example.com/api/test",
        download: "http://example.com/download/test"
      )

      refs3 = described_class.new(
        resource: "http://example.com/api/different",
        download: "http://example.com/download/different"
      )

      # Compare individual attributes instead of object equality
      expect(refs1.resource).to eq(refs2.resource)
      expect(refs1.download).to eq(refs2.download)
      expect(refs1.resource).not_to eq(refs3.resource)
    end
  end
end
