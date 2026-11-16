# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Job::File do
  # job.file of spec/cassettes/2_0/job/get_printing.yml
  let(:attributes) do
    { date: 1_794_809_291, display: "job_test.gcode", name: "job_test.gcode", origin: "local",
      path: "job_test.gcode", size: 2073, upload: false }
  end

  describe ".deserialize" do
    subject(:file) { described_class.deserialize(attributes.dup) }

    its(:name)           { is_expected.to eq "job_test.gcode" }
    its(:display_name)   { is_expected.to eq "job_test.gcode" }
    its(:path)           { is_expected.to eq "job_test.gcode" }
    its(:origin)         { is_expected.to eq "local" }
    its(:size)           { is_expected.to eq 2073 }
    its(:date_timestamp) { is_expected.to eq 1_794_809_291 }
    its(:date)           { is_expected.to eq Time.at(1_794_809_291) }
    its(:upload)         { is_expected.to be false }
    its(:extra)          { is_expected.to be_nil }

    it "collects the unknown fields" do
      file = described_class.deserialize(attributes.merge(storage: "local"))

      expect(file.extra).to eq(storage: "local")
    end

    context "without a selected file" do
      subject(:file) { described_class.deserialize({}) }

      its(:name) { is_expected.to be_nil }
      its(:date) { is_expected.to be_nil }
      its(:upload) { is_expected.to be_nil }
      its(:to_h) { is_expected.to eq({}) }
    end
  end

  describe "#to_h" do
    it "has the API keys" do
      expect(described_class.deserialize(attributes.dup).to_h).to eq attributes
    end

    it "leaves out the empty fields and keeps the extra ones" do
      file = described_class.deserialize({ name: "a.gcode", storage: "local" })

      expect(file.to_h).to eq(name: "a.gcode", storage: "local")
    end
  end

  describe "hash access (deprecated)" do
    subject(:file) { described_class.deserialize(attributes.dup) }

    before do
      Octoprint::Deprecation.reset!
      allow(Kernel).to receive(:warn)
    end

    after { Octoprint::Deprecation.reset! }

    it "reads a field by its API key, like the hash it replaces" do
      expect(file[:display]).to eq "job_test.gcode"
      expect(file[:date]).to eq 1_794_809_291
      expect(file[:unknown]).to be_nil
    end

    it "fetches a field like a hash" do
      expect(file.fetch(:name)).to eq "job_test.gcode"
      expect(file.fetch(:unknown, "default")).to eq "default"
      expect(file.fetch(:unknown) { |key| key }).to eq :unknown
      expect { file.fetch(:unknown) }.to raise_error(KeyError)
    end

    it "digs and checks keys like a hash" do
      expect(file.dig(:name)).to eq "job_test.gcode" # rubocop:disable Style/SingleArgumentDig
      expect(file.key?(:upload)).to be true
      expect(described_class.deserialize({}).key?(:name)).to be false
    end

    it "warns once per method" do
      2.times { file[:name] }
      file.key?(:name)

      expect(Kernel).to have_received(:warn).with(/Octoprint::Job::File#\[\] is deprecated: .*file\.name/).once
      expect(Kernel).to have_received(:warn).with(/Octoprint::Job::File#key\? is deprecated/).once
    end
  end
end
