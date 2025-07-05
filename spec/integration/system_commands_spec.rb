# typed: false
# frozen_string_literal: true

RSpec.describe Octoprint::SystemCommands, type: :integration do
  include_context "with default Octoprint config"

  describe ".list", vcr: { cassette_name: "system_commands/list" } do
    use_octoprint_server

    subject(:commands) { described_class.list }

    it { is_expected.to be_a described_class }

    its(:core) { is_expected.to be_an Array }
    its(:custom) { is_expected.to be_an Array }

    describe "core commands" do
      subject(:core_commands) { commands.core }

      it { is_expected.not_to be_empty }

      it "contains Command objects" do
        expect(core_commands).to all(be_a(Octoprint::SystemCommands::Command))
      end

      it "includes standard system commands" do
        actions = core_commands.map(&:action)
        expect(actions).to include("shutdown", "reboot", "restart")
      end

      it "has proper attributes for each command" do
        first_command = core_commands.first
        expect(first_command).to be_a Octoprint::SystemCommands::Command
        expect(first_command.action).to be_a String
        expect(first_command.name).to be_a String
        expect(first_command.source).to eq "core"
        expect(first_command.resource).to match(%r{^https?://.+/api/system/commands/core/.+})
        expect(first_command.confirm).to be_nil.or be_a(String)
      end
    end

    describe "custom commands" do
      subject(:custom_commands) { commands.custom }

      it { is_expected.to be_an Array }

      it "contains Command objects if any exist" do
        expect(custom_commands).to all(be_a(Octoprint::SystemCommands::Command)) unless custom_commands.empty?
      end
    end
  end
end
