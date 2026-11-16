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

      its("file.to_h") do
        is_expected.to eq({ date: 1_648_233_209, display: "fidget_star_standing_15_48 (1).gcode",
                            name: "fidget_star_standing_15_48 (1).gcode", origin: "local",
                            path: "fidget_star_standing_15_48 (1).gcode", size: 33_624_386 })
      end

      its(:estimated_print_time) { is_expected.to eq 20_450.349227480252 }
      its(:last_print_time)      { is_expected.to eq 31_100.379534339067 }
      its(:average_print_time)   { is_expected.to eq 31_100.379534339067 }
      its(:user)                 { is_expected.to eq "sophie" }
      its(:filament)             { is_expected.to eq({ tool0: { length: 7970.985739999992, volume: 0.0 } }) }
      its(:extra)                { is_expected.to be_nil }
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

  # Recorded with the virtual printer connected: idle without a selected file, then while printing a small
  # job_test.gcode (60 moves) that had been printed to completion once before, so 1.11.8 has its print times.
  shared_examples "an idle job" do
    it { is_expected.to be_a described_class }
    its(:state) { is_expected.to eq "Operational" }
    its(:error) { is_expected.to be_nil }
    its(:extra) { is_expected.to be_nil }

    its("information.file") { is_expected.to be_a Octoprint::Job::File }
    its("information.file.to_h") { is_expected.to eq({}) }
    its("information.file.name") { is_expected.to be_nil }
    its("information.file.upload") { is_expected.to be_nil }
    its("information.estimated_print_time") { is_expected.to be_nil }
    its("information.last_print_time") { is_expected.to be_nil }
    its("information.filament") { is_expected.to be_nil }
    its("information.user") { is_expected.to be_nil }
    its("information.extra") { is_expected.to be_nil }

    its(:progress) { is_expected.to be_a Octoprint::Job::Progress }
    its("progress.completion") { is_expected.to be_nil }
    its("progress.filepos") { is_expected.to be_nil }
    its("progress.print_time") { is_expected.to be_nil }
    its("progress.print_time_left") { is_expected.to be_nil }
    its("progress.print_time_left_origin") { is_expected.to be_nil }
  end

  shared_examples "a printing job" do |server_version|
    # The values that differ between the recordings
    let(:expected) do
      {
        # 1.11.8: no upload flag, print times from the file statistics, time left from the average print time
        "1.11" => { upload: nil, print_time: 31.265309458001866, time_left: 26, origin: "average",
                    filament: { tool0: { length: 60.0, volume: 0.0 } } },
        # 2.0: an upload flag, no print times, time left from the analysis, a filament weight
        "2.0" => { upload: false, print_time: nil, time_left: 30, origin: "analysis",
                   filament: { tool0: { length: 60.0, volume: 0.0, weight: nil } } }
      }.fetch(server_version)
    end

    it { is_expected.to be_a described_class }
    its(:state) { is_expected.to eq "Printing" }
    its(:error) { is_expected.to be_nil }
    its(:extra) { is_expected.to be_nil }

    describe "#information" do
      subject(:information) { described_class.get.information }

      its("file.name") { is_expected.to eq "job_test.gcode" }
      its("file.display_name") { is_expected.to eq "job_test.gcode" }
      its("file.path") { is_expected.to eq "job_test.gcode" }
      its("file.origin") { is_expected.to eq "local" }
      its("file.size") { is_expected.to eq 2073 }
      its("file.date") { is_expected.to eq Time.at(1_794_809_291) }
      its("file.upload") { is_expected.to eq expected[:upload] }
      its(:estimated_print_time) { is_expected.to eq 34.949892090338835 }
      its(:filament) { is_expected.to eq expected[:filament] }
      its(:user) { is_expected.to eq "admin" }
      its(:extra) { is_expected.to be_nil }

      it "only has the print times of the file on 1.x servers" do
        expect(information.last_print_time).to eq expected[:print_time]
        expect(information.average_print_time).to eq expected[:print_time]
      end
    end

    describe "#progress" do
      subject { described_class.get.progress }

      its(:completion) { is_expected.to eq 16.160154365653643 }
      its(:filepos) { is_expected.to eq 335 }
      its(:print_time) { is_expected.to eq 4 }
      its(:print_time_left) { is_expected.to eq expected[:time_left] }
      its(:print_time_left_origin) { is_expected.to eq expected[:origin] }
      its(:extra) { is_expected.to be_nil }
    end
  end

  describe ".get on every supported server with its own API" do
    subject { described_class.get }

    use_octoprint_server

    on_octoprint_versions do |version|
      describe "when idle", vcr: { cassette_name: "job/get_idle" } do
        it_behaves_like "an idle job"
      end

      describe "when printing", vcr: { cassette_name: "job/get_printing" } do
        it_behaves_like "a printing job", version
      end
    end
  end

  # 2.0 answers the 1.x API with new fields (error, job.file.display/upload) and null for lastPrintTime
  describe ".get on OctoPrint 2.0 with the 1.11 API", api_version: "1.11", octoprint: "2.0" do
    subject { described_class.get }

    use_octoprint_server

    describe "when idle", vcr: { cassette_name: "job/get_idle_api_1_11" } do
      it_behaves_like "an idle job"
    end

    describe "when printing", vcr: { cassette_name: "job/get_printing_api_1_11" } do
      it_behaves_like "a printing job", "2.0"
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
