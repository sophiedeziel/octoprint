# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Printer::Command do
  include_context "with default Octoprint config"

  describe "inheritance and configuration" do
    it "inherits from BaseResource" do
      expect(described_class).to be < Octoprint::BaseResource
    end

    it "has correct resource path" do
      expect(described_class.instance_variable_get(:@path)).to eq("/api/printer/command")
    end
  end

  describe ".issue" do
    before do
      allow(described_class).to receive(:post).and_return(true)
    end

    it "posts a single command" do
      described_class.issue(command: "M106")

      expect(described_class).to have_received(:post).with(params: { command: "M106" })
    end

    it "posts multiple commands" do
      described_class.issue(commands: ["M18", "M106 S0"])

      expect(described_class).to have_received(:post).with(params: { commands: ["M18", "M106 S0"] })
    end

    it "posts a script" do
      described_class.issue(script: "afterPrintCancelled")

      expect(described_class).to have_received(:post).with(params: { script: "afterPrintCancelled" })
    end

    it "includes the parameters" do
      described_class.issue(commands: ["G91", "G1 X%(distance)s", "G90"], parameters: { distance: 10 })

      expect(described_class).to have_received(:post).with(
        params: { commands: ["G91", "G1 X%(distance)s", "G90"], parameters: { distance: 10 } }
      )
    end

    it "includes the parameters and context of a script" do
      described_class.issue(script: "custom", parameters: { speed: 255 }, context: { name: "test" })

      expect(described_class).to have_received(:post).with(
        params: { script: "custom", parameters: { speed: 255 }, context: { name: "test" } }
      )
    end

    it "returns the post result" do
      expect(described_class.issue(command: "M106")).to be(true)
    end

    context "with invalid arguments" do
      it "raises ArgumentError when nothing is given" do
        expect { described_class.issue }
          .to raise_error(ArgumentError, "Exactly one of command, commands or script must be provided")
      end

      it "raises ArgumentError when only parameters are given" do
        expect { described_class.issue(parameters: { speed: 255 }) }
          .to raise_error(ArgumentError, "Exactly one of command, commands or script must be provided")
      end

      it "raises ArgumentError when command and commands are given" do
        expect { described_class.issue(command: "M106", commands: ["M18"]) }
          .to raise_error(ArgumentError, "Exactly one of command, commands or script must be provided")
      end

      it "raises ArgumentError when command and script are given" do
        expect { described_class.issue(command: "M106", script: "afterPrintCancelled") }
          .to raise_error(ArgumentError, "Exactly one of command, commands or script must be provided")
      end

      it "raises ArgumentError when commands and script are given" do
        expect { described_class.issue(commands: ["M18"], script: "afterPrintCancelled") }
          .to raise_error(ArgumentError, "Exactly one of command, commands or script must be provided")
      end

      it "raises ArgumentError when all three are given" do
        expect { described_class.issue(command: "M106", commands: ["M18"], script: "afterPrintCancelled") }
          .to raise_error(ArgumentError, "Exactly one of command, commands or script must be provided")
      end

      it "raises ArgumentError when context is given with a command" do
        expect { described_class.issue(command: "M106", context: { name: "test" }) }
          .to raise_error(ArgumentError, "context can only be used with script")
      end

      it "raises ArgumentError when context is given with commands" do
        expect { described_class.issue(commands: ["M18"], context: { name: "test" }) }
          .to raise_error(ArgumentError, "context can only be used with script")
      end

      it "does not post anything" do
        expect { described_class.issue }.to raise_error(ArgumentError)

        expect(described_class).not_to have_received(:post)
      end
    end
  end

  describe ".send_command" do
    before do
      allow(described_class).to receive(:issue).and_return(true)
    end

    it "delegates to issue with the command" do
      described_class.send_command("M106")

      expect(described_class).to have_received(:issue).with(command: "M106", parameters: nil)
    end

    it "passes the parameters" do
      described_class.send_command("M106 S%(speed)s", parameters: { speed: 255 })

      expect(described_class).to have_received(:issue).with(command: "M106 S%(speed)s", parameters: { speed: 255 })
    end
  end

  describe ".send_commands" do
    before do
      allow(described_class).to receive(:issue).and_return(true)
    end

    it "delegates to issue with the commands" do
      described_class.send_commands(["M18", "M106 S0"])

      expect(described_class).to have_received(:issue).with(commands: ["M18", "M106 S0"], parameters: nil)
    end

    it "passes the parameters" do
      described_class.send_commands(["G1 X%(x)s"], parameters: { x: 10 })

      expect(described_class).to have_received(:issue).with(commands: ["G1 X%(x)s"], parameters: { x: 10 })
    end
  end

  describe ".run_script" do
    before do
      allow(described_class).to receive(:issue).and_return(true)
    end

    it "delegates to issue with the script" do
      described_class.run_script("afterPrintCancelled")

      expect(described_class).to have_received(:issue).with(
        script: "afterPrintCancelled",
        parameters: nil,
        context: nil
      )
    end

    it "passes the parameters and context" do
      described_class.run_script("custom", parameters: { speed: 255 }, context: { name: "test" })

      expect(described_class).to have_received(:issue).with(
        script: "custom",
        parameters: { speed: 255 },
        context: { name: "test" }
      )
    end
  end

  describe ".custom_controls" do
    let(:response) do
      {
        controls: [
          {
            name: "Fan",
            type: "section",
            layout: "horizontal",
            children: [
              {
                name: "Enable Fan",
                type: "parametric_command",
                command: "M106 S%(speed)s",
                input: [
                  { name: "Speed (0-255)", parameter: "speed", default: 255, slider: { min: 0, max: 255 } }
                ]
              },
              { name: "Disable Fan", type: "command", command: "M107" }
            ]
          },
          {
            name: "Reporting",
            type: "feedback_command",
            command: "M114",
            regex: "^X:([-+]?[0-9.]+)",
            template: "Position: X={0}",
            key: "abc123",
            template_key: "def456"
          }
        ]
      }
    end

    before do
      allow(described_class).to receive(:fetch_resource).and_return(response)
    end

    it "fetches the raw custom controls" do
      described_class.custom_controls

      expect(described_class).to have_received(:fetch_resource).with("custom", deserialize: false)
    end

    it "returns the custom controls" do
      controls = described_class.custom_controls

      expect(controls).to all(be_a(Octoprint::Printer::CustomControl))
      expect(controls.map(&:name)).to eq(%w[Fan Reporting])
    end

    it "deserializes nested children and inputs" do
      fan = described_class.custom_controls.first

      expect(fan).to be_container
      expect(fan.children.map(&:name)).to eq(["Enable Fan", "Disable Fan"])
      expect(fan.children.first.input.first).to be_a(Octoprint::Printer::CustomControl::Input)
      expect(fan.children.first.input.first.parameter).to eq("speed")
    end

    it "deserializes feedback controls" do
      reporting = described_class.custom_controls.last

      expect(reporting).not_to be_container
      expect(reporting.key).to eq("abc123")
      expect(reporting.template_key).to eq("def456")
    end

    context "when no controls are configured" do
      let(:response) { { controls: [] } }

      it "returns an empty array" do
        expect(described_class.custom_controls).to eq([])
      end
    end

    context "when the controls key is missing" do
      let(:response) { {} }

      it "returns an empty array" do
        expect(described_class.custom_controls).to eq([])
      end
    end
  end
end
