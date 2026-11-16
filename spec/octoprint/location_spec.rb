# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Location do
  # Reads the deprecated SDCard constant without printing Ruby's deprecation warning (shown with -W:deprecated)
  def with_deprecation_warnings(enabled)
    previous = Warning[:deprecated]
    Warning[:deprecated] = enabled
    yield
  ensure
    Warning[:deprecated] = previous
  end

  def sdcard
    with_deprecation_warnings(false) { described_class::SDCard }
  end

  describe "enum values" do
    it "has Local enum value" do
      expect(described_class::Local).to be_a(described_class)
    end

    it "has Printer enum value" do
      expect(described_class::Printer).to be_a(described_class)
    end

    it "has the correct serialized values" do
      expect(described_class::Local.serialize).to eq("local")
      expect(described_class::Printer.serialize).to eq("printer")
    end

    it "has the 1.x name of the printer storage" do
      expect(described_class::LEGACY_PRINTER).to eq("sdcard")
    end
  end

  describe "SDCard" do
    it "is the same object as Printer" do
      expect(sdcard).to equal(described_class::Printer)
    end

    it "serializes to printer" do
      expect(sdcard.serialize).to eq("printer")
    end

    it "is a deprecated constant" do
      expect { with_deprecation_warnings(true) { described_class::SDCard } }
        .to output(/SDCard is deprecated/).to_stderr
    end

    it "doesn't warn when deprecation warnings are off" do
      expect { sdcard }.not_to output.to_stderr
    end
  end

  describe "#to_s" do
    it "returns the serialized value" do
      expect(described_class::Local.to_s).to eq("local")
      expect(described_class::Printer.to_s).to eq("printer")
    end

    it "can be interpolated in API paths" do
      expect("/api/files/#{described_class::Printer}").to eq("/api/files/printer")
    end
  end

  describe "enum behavior" do
    it "can be used in case statements" do
      location = described_class::Printer
      result = case location
               when described_class::Local
                 "local storage"
               when described_class::Printer
                 "printer storage"
               end
      expect(result).to eq("printer storage")
    end

    it "matches the SDCard alias in case statements" do
      result = case sdcard
               when described_class::Printer then "printer storage"
               end
      expect(result).to eq("printer storage")
    end

    it "provides all enum values" do
      expect(described_class.values).to contain_exactly(
        described_class::Local,
        described_class::Printer
      )
    end
  end

  describe "serialization" do
    it "serializes to correct string values" do
      expect(described_class::Local.serialize).to eq("local")
      expect(described_class::Printer.serialize).to eq("printer")
    end

    it "deserializes from string values" do
      expect(described_class.deserialize("local")).to eq(described_class::Local)
      expect(described_class.deserialize("printer")).to eq(described_class::Printer)
    end

    it "doesn't deserialize the 1.x sdcard name, which Files::Legacy renames" do
      expect(described_class.try_deserialize("sdcard")).to be_nil
    end

    it "try_deserialize returns nil for an unknown value" do
      expect(described_class.try_deserialize("usb")).to be_nil
    end

    it "deserialize raises for an unknown value" do
      expect { described_class.deserialize("usb") }.to raise_error(KeyError)
    end
  end
end
