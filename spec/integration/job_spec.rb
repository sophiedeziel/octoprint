# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Job, type: :integration do
  include_context "with default Octoprint config"

  let(:job_params) do
    {
      job: {
        file: {
          name: "whistle_v2.gcode",
          origin: "local",
          size: 1_468_987,
          date: 1_378_847_754
        },
        estimated_print_time: 8811,
        filament: {
          tool0: {
            length: 810,
            volume: 5.36
          }
        }
      },
      progress: {
        completion: 0.2298468264184775,
        filepos: 337_942,
        print_time: 276,
        print_time_left: 912
      },
      state: "Printing"
    }
  end

  describe "The connection object" do
    subject { described_class.deserialize(job_params) }

    its(:information) { is_expected.to be_a Octoprint::Job::Information }
    its(:progress)    { is_expected.to be_a Octoprint::Job::Progress }
    its(:state)       { is_expected.to eq "Printing" }
    its(:error)       { is_expected.to be_nil }
  end

  describe ".get", vcr: { cassette_name: "job/get" } do
    subject { described_class.get }

    before do
      Octoprint.configure(host: host, api_key: api_key)
    end

    it { is_expected.to be_a described_class }
    its(:information) { is_expected.to be_a Octoprint::Job::Information }
    its(:progress)    { is_expected.to be_a Octoprint::Job::Progress }
    its(:state)       { is_expected.to eq "Printing" }
    its(:error)       { is_expected.to be_nil }

    describe "#information" do
      subject { described_class.get.information }

      its(:file) do
        is_expected.to eq({ date: 1_648_233_209, display: "fidget_star_standing_15_48 (1).gcode",
                            name: "fidget_star_standing_15_48 (1).gcode", origin: "local",
                            path: "fidget_star_standing_15_48 (1).gcode", size: 33_624_386 })
      end

      its(:estimated_print_time) { is_expected.to eq 20_450.349227480252 }
      its(:last_print_time)      { is_expected.to eq 31_100.379534339067 }
      its(:filament)             { is_expected.to eq({ tool0: { length: 7970.985739999992, volume: 0.0 } }) }
    end

    describe "#progress" do
      subject { described_class.get.progress }

      its(:completion) do
        is_expected.to eq(0.0006334688163525127)
      end

      its(:filepos) { is_expected.to eq 213 }
      its(:print_time) { is_expected.to eq 1 }
      its(:print_time_left) { is_expected.to eq 31_099 }
      its(:print_time_left_origin) { is_expected.to eq "average" }
    end
  end

  describe ".start", vcr: { cassette_name: "job/start" } do
    use_octoprint_server

    subject(:start_job) { described_class.start }

    it { expect(start_job).to be true }
  end

  describe ".cancel", vcr: { cassette_name: "job/cancel" } do
    use_octoprint_server

    subject(:cancel_job) { described_class.cancel }

    it { expect(cancel_job).to be true }
  end

  describe ".restart", vcr: { cassette_name: "job/restart" } do
    use_octoprint_server

    subject(:restart_job) { described_class.restart }

    it { expect(restart_job).to be true }
  end

  describe ".pause", vcr: { cassette_name: "job/pause_with_action_pause" } do
    use_octoprint_server

    subject(:pause_job) { described_class.pause }

    it { expect(pause_job).to be true }
  end

  describe ".resume", vcr: { cassette_name: "job/pause_with_action_resume" } do
    use_octoprint_server

    subject(:resume_job) { described_class.resume }

    it { expect(resume_job).to be true }
  end

  describe ".issue_command", vcr: { cassette_name: "job/issue_command" } do
    use_octoprint_server

    subject(:issue_command) { described_class.issue_command(command: "pause") }

    it { expect(issue_command).to be true }
  end
end
