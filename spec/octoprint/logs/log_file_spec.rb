# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Logs::LogFile do
  describe "#initialize" do
    let(:log_file_data) do
      {
        name: "octoprint.log",
        size: 1024,
        date: 1_640_995_200,
        refs: { resource: "http://test.local/logs/octoprint.log", download: "http://test.local/logs/octoprint.log/download" }
      }
    end

    it "initializes with all required attributes" do
      log_file = described_class.new(**log_file_data)

      expect(log_file.name).to eq("octoprint.log")
      expect(log_file.size).to eq(1024)
      expect(log_file.date).to eq(1_640_995_200)
      expect(log_file.refs).to be_a(Octoprint::Logs::References)
      expect(log_file.refs.resource).to eq("http://test.local/logs/octoprint.log")
      expect(log_file.refs.download).to eq("http://test.local/logs/octoprint.log/download")
    end

    it "initializes with minimal required attributes" do
      minimal_data = { name: "test.log", size: 512, date: 1_640_995_200 }
      log_file = described_class.new(**minimal_data)

      expect(log_file.name).to eq("test.log")
      expect(log_file.size).to eq(512)
      expect(log_file.date).to eq(1_640_995_200)
      expect(log_file.refs).to be_nil
    end
  end

  describe "inheritance and modules" do
    it "includes Deserializable" do
      expect(described_class).to include(Octoprint::Deserializable)
    end

    it "includes AutoInitializable" do
      expect(described_class).to include(Octoprint::AutoInitializable)
    end
  end

  describe "#to_s" do
    it "returns a human-readable string representation" do
      log_file = described_class.new(name: "octoprint.log", size: 1024, date: 1_640_995_200)

      result = log_file.to_s

      expect(result).to include("octoprint.log")
      expect(result).to include("1024 bytes")
      expect(result).to include("modified:")
    end

    it "handles different file sizes" do
      log_file = described_class.new(name: "large.log", size: 1_048_576, date: 1_640_995_200)

      result = log_file.to_s

      expect(result).to include("1048576 bytes")
    end
  end

  describe "#modification_time" do
    it "converts Unix timestamp to Time object" do
      timestamp = 1_640_995_200
      log_file = described_class.new(name: "test.log", size: 100, date: timestamp)

      time = log_file.modification_time

      expect(time).to be_a(Time)
      expect(time.to_i).to eq(timestamp)
    end

    it "handles different timestamps correctly" do
      timestamp = 1_609_459_200 # 2021-01-01 00:00:00 UTC
      log_file = described_class.new(name: "test.log", size: 100, date: timestamp)

      time = log_file.modification_time

      # Use UTC time to avoid timezone issues
      expect(time.utc.year).to eq(2021)
      expect(time.utc.month).to eq(1)
      expect(time.utc.day).to eq(1)
    end
  end

  describe "auto_attrs configuration" do
    it "has correct attribute configuration" do
      attrs = described_class.auto_attrs

      expect(attrs[:name][:type]).to eq(String)
      expect(attrs[:name][:nilable]).to be false
      expect(attrs[:size][:type]).to eq(Integer)
      expect(attrs[:size][:nilable]).to be false
      expect(attrs[:date][:type]).to eq(Integer)
      expect(attrs[:date][:nilable]).to be false
      expect(attrs[:refs][:type]).to eq(Octoprint::Logs::References)
      expect(attrs[:refs][:nilable]).to be true
    end
  end

  describe "deserialization" do
    let(:api_data) do
      {
        name: "test.log",
        size: 2048,
        date: 1_640_995_200,
        refs: { resource: "http://test.local/logs/test.log" }
      }
    end

    it "deserializes from API data correctly" do
      log_file = described_class.deserialize(api_data)

      expect(log_file.name).to eq("test.log")
      expect(log_file.size).to eq(2048)
      expect(log_file.date).to eq(1_640_995_200)
      expect(log_file.refs).to be_a(Octoprint::Logs::References)
      expect(log_file.refs.resource).to eq("http://test.local/logs/test.log")
    end

    it "handles missing optional refs field" do
      data_without_refs = api_data.except(:refs)
      log_file = described_class.deserialize(data_without_refs)

      expect(log_file.refs).to be_nil
    end
  end
end
