# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Job do
  include_context "with default Octoprint config"

  describe "inheritance and configuration" do
    it "inherits from BaseResource" do
      expect(described_class).to be < Octoprint::BaseResource
    end

    it "has correct resource path" do
      expect(described_class.instance_variable_get(:@path)).to eq("/api/job")
    end
  end

  describe ".deserialize" do
    it "reads the 2.0 response of an idle printer, where the empty fields are left out" do
      job = described_class.deserialize({ job: { file: {} }, progress: {}, state: "Operational" })

      expect(job.information.file).to be_a Octoprint::Job::File
      expect(job.information.last_print_time).to be_nil
      expect(job.progress.completion).to be_nil
      expect(job.extra).to be_nil
    end

    it "doesn't fail without job information or progress" do
      job = described_class.deserialize({ state: "Offline" })

      expect(job.information).to be_nil
      expect(job.progress).to be_nil
    end

    it "keeps the unknown fields of the job and its progress" do
      job = described_class.deserialize({ job: { file: {}, origin: "x" }, progress: { layer: 3 }, state: "Printing" })

      expect(job.information.extra).to eq(origin: "x")
      expect(job.progress.extra).to eq(layer: 3)
    end
  end

  describe ".issue_command" do
    before do
      allow(described_class).to receive(:post).and_return(true)
    end

    it "posts with the correct command" do
      described_class.issue_command(command: "start")

      expect(described_class).to have_received(:post).with(
        params: { command: "start" }
      )
    end

    it "merges options into the params" do
      described_class.issue_command(command: "pause", options: { action: "toggle" })

      expect(described_class).to have_received(:post).with(
        params: { command: "pause", action: "toggle" }
      )
    end
  end

  describe ".start" do
    before do
      allow(described_class).to receive(:issue_command).and_return(true)
    end

    it "delegates to issue_command with start" do
      described_class.start

      expect(described_class).to have_received(:issue_command).with(command: "start")
    end
  end

  describe ".cancel" do
    before do
      allow(described_class).to receive(:issue_command).and_return(true)
    end

    it "delegates to issue_command with cancel" do
      described_class.cancel

      expect(described_class).to have_received(:issue_command).with(command: "cancel")
    end
  end

  describe ".restart" do
    before do
      allow(described_class).to receive(:issue_command).and_return(true)
    end

    it "delegates to issue_command with restart" do
      described_class.restart

      expect(described_class).to have_received(:issue_command).with(command: "restart")
    end
  end

  describe ".pause" do
    before do
      allow(described_class).to receive(:issue_command).and_return(true)
    end

    it "delegates to issue_command with pause action" do
      described_class.pause

      expect(described_class).to have_received(:issue_command).with(
        command: "pause",
        options: { action: "pause" }
      )
    end
  end

  describe ".resume" do
    before do
      allow(described_class).to receive(:issue_command).and_return(true)
    end

    it "delegates to issue_command with resume action" do
      described_class.resume

      expect(described_class).to have_received(:issue_command).with(
        command: "pause",
        options: { action: "resume" }
      )
    end
  end
end
