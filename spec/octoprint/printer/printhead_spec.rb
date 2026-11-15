# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Printer::Printhead do
  include_context "with default Octoprint config"

  describe "inheritance and configuration" do
    it "inherits from BaseResource" do
      expect(described_class).to be < Octoprint::BaseResource
    end

    it "has correct resource path" do
      expect(described_class.instance_variable_get(:@path)).to eq("/api/printer/printhead")
    end
  end

  describe ".issue_command" do
    before do
      allow(described_class).to receive(:post).and_return(true)
    end

    it "posts with the correct command" do
      described_class.issue_command(command: "home")

      expect(described_class).to have_received(:post).with(params: { command: "home" })
    end

    it "merges options into the params" do
      described_class.issue_command(command: "home", options: { axes: ["z"] })

      expect(described_class).to have_received(:post).with(params: { command: "home", axes: ["z"] })
    end

    it "returns the post result" do
      expect(described_class.issue_command(command: "home")).to be(true)
    end
  end

  describe ".jog" do
    before do
      allow(described_class).to receive(:issue_command).and_return(true)
    end

    it "delegates to issue_command with the given amounts" do
      described_class.jog(x: 10, y: -5, z: 0.02)

      expect(described_class).to have_received(:issue_command).with(
        command: "jog",
        options: { x: 10, y: -5, z: 0.02 }
      )
    end

    it "omits the axes and options that aren't given" do
      described_class.jog(z: 1)

      expect(described_class).to have_received(:issue_command).with(command: "jog", options: { z: 1 })
    end

    it "sends an absolute move with a speed" do
      described_class.jog(x: 100, y: 100, absolute: true, speed: 3000)

      expect(described_class).to have_received(:issue_command).with(
        command: "jog",
        options: { x: 100, y: 100, absolute: true, speed: 3000 }
      )
    end

    it "keeps false values" do
      described_class.jog(x: 1, absolute: false, speed: false)

      expect(described_class).to have_received(:issue_command).with(
        command: "jog",
        options: { x: 1, absolute: false, speed: false }
      )
    end

    it "sends empty options when nothing is given" do
      described_class.jog

      expect(described_class).to have_received(:issue_command).with(command: "jog", options: {})
    end
  end

  describe ".home" do
    before do
      allow(described_class).to receive(:issue_command).and_return(true)
    end

    it "homes all axes by default" do
      described_class.home

      expect(described_class).to have_received(:issue_command).with(
        command: "home",
        options: { axes: %w[x y z] }
      )
    end

    it "homes the given axes" do
      described_class.home(axes: %w[x y])

      expect(described_class).to have_received(:issue_command).with(command: "home", options: { axes: %w[x y] })
    end

    it "converts symbol axes to strings" do
      described_class.home(axes: %i[z])

      expect(described_class).to have_received(:issue_command).with(command: "home", options: { axes: ["z"] })
    end
  end

  describe ".feedrate" do
    before do
      allow(described_class).to receive(:issue_command).and_return(true)
    end

    it "delegates to issue_command with an integer factor" do
      described_class.feedrate(105)

      expect(described_class).to have_received(:issue_command).with(command: "feedrate", options: { factor: 105 })
    end

    it "delegates to issue_command with a float factor" do
      described_class.feedrate(1.05)

      expect(described_class).to have_received(:issue_command).with(command: "feedrate", options: { factor: 1.05 })
    end
  end
end
