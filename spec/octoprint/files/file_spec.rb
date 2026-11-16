# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Files::File do
  describe "#user" do
    it "is the user who uploaded the file" do
      file = described_class.deserialize(
        { name: "test_file.gcode", origin: "local", path: "test_file.gcode", user: "admin" }
      )

      expect(file.user).to eq("admin")
    end

    it "is nil for a printer file" do
      file = described_class.deserialize({ name: "test_f-1.gco", origin: "printer", path: "test_f-1.gco" })

      expect(file.user).to be_nil
      expect(file.origin).to eq(Octoprint::Location::Printer)
    end
  end

  describe "#date" do
    it "returns nil when date_timestamp is nil" do
      file = described_class.new(name: "test.gcode", origin: Octoprint::Location::Local, path: "test.gcode")
      expect(file.date).to be_nil
    end

    it "returns Time object when date_timestamp is zero" do
      file = described_class.new(
        name: "test.gcode",
        origin: Octoprint::Location::Local,
        path: "test.gcode",
        date_timestamp: 0
      )
      expect(file.date).to be_a(Time)
      expect(file.date).to eq(Time.at(0))
    end

    it "returns Time object when date_timestamp is set" do
      timestamp = 1_648_233_209
      file = described_class.new(
        name: "test.gcode",
        origin: Octoprint::Location::Local,
        path: "test.gcode",
        date_timestamp: timestamp
      )
      expect(file.date).to be_a(Time)
      expect(file.date).to eq(Time.at(timestamp))
    end

    it "handles various falsy values for date_timestamp" do
      # Test falsy values that make sense for timestamps
      falsy_values = [nil, false]

      falsy_values.each do |falsy_value|
        file = described_class.new(
          name: "test.gcode",
          origin: Octoprint::Location::Local,
          path: "test.gcode",
          date_timestamp: falsy_value
        )

        # All these falsy values should return nil
        expect(file.date).to be_nil
      end
    end
  end
end
