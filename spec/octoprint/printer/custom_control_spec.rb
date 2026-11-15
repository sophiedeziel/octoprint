# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Printer::CustomControl do
  describe "modules" do
    subject { described_class.new }

    it { is_expected.to be_a(Octoprint::Deserializable) }
    it { is_expected.to be_a(Octoprint::AutoInitializable) }
  end

  describe ".deserialize" do
    subject(:control) { described_class.deserialize(data) }

    context "with a container" do
      let(:data) do
        {
          name: "Fan",
          type: "section",
          layout: "horizontal_grid",
          collapsed: true,
          children: [
            {
              name: "Enable Fan",
              type: "parametric_command",
              command: "M106 S%(speed)s",
              width: "4",
              offset: "1",
              additional_classes: "btn-success",
              input: [
                { name: "Speed (0-255)", parameter: "speed", default: 255, slider: { min: 0, max: 255 } }
              ]
            },
            {
              name: "Sub section",
              children: [
                { name: "Disable Fan", command: "M107", confirm: "Really?" }
              ]
            }
          ]
        }
      end

      it "deserializes the container attributes" do
        expect(control.name).to eq("Fan")
        expect(control.type).to eq("section")
        expect(control.layout).to eq("horizontal_grid")
        expect(control.collapsed).to be(true)
      end

      it "is a container" do
        expect(control).to be_container
      end

      it "deserializes the children into custom controls" do
        expect(control.children).to all(be_a(described_class))
        expect(control.children.map(&:name)).to eq(["Enable Fan", "Sub section"])
      end

      it "deserializes the child control attributes" do
        child = control.children.first

        expect(child).not_to be_container
        expect(child.command).to eq("M106 S%(speed)s")
        expect(child.width).to eq("4")
        expect(child.offset).to eq("1")
        expect(child.additional_classes).to eq("btn-success")
      end

      it "deserializes the child inputs" do
        input = control.children.first.input

        expect(input).to all(be_a(described_class::Input))
        expect(input.first.name).to eq("Speed (0-255)")
        expect(input.first.parameter).to eq("speed")
        expect(input.first.default).to eq(255)
        expect(input.first.slider).to eq({ min: 0, max: 255 })
      end

      it "deserializes deeply nested children" do
        nested = control.children.last

        expect(nested).to be_container
        expect(nested.children.first).to be_a(described_class)
        expect(nested.children.first.command).to eq("M107")
        expect(nested.children.first.confirm).to eq("Really?")
      end
    end

    context "with an empty container" do
      let(:data) { { name: "Empty", children: [] } }

      it "is still a container" do
        expect(control.children).to eq([])
        expect(control).to be_container
      end
    end

    context "with a feedback control" do
      let(:data) do
        {
          name: "Reporting",
          type: "feedback_command",
          command: "M114",
          regex: "^X:([-+]?[0-9.]+)",
          template: "Position: X={0}",
          key: "abc123",
          template_key: "def456",
          enabled: "isOperational()"
        }
      end

      it "deserializes the feedback attributes" do
        expect(control.regex).to eq("^X:([-+]?[0-9.]+)")
        expect(control.template).to eq("Position: X={0}")
        expect(control.enabled).to eq("isOperational()")
      end

      it "deserializes the generated keys" do
        expect(control.key).to eq("abc123")
        expect(control.template_key).to eq("def456")
      end

      it "is not a container" do
        expect(control).not_to be_container
        expect(control.children).to be_nil
      end
    end

    context "with commands, a script and javascript" do
      let(:data) do
        {
          name: "Combo",
          commands: ["M18", "M106 S0"],
          script: "afterPrintCancelled",
          javascript: "alert('done')"
        }
      end

      it "deserializes them" do
        expect(control.commands).to eq(["M18", "M106 S0"])
        expect(control.script).to eq("afterPrintCancelled")
        expect(control.javascript).to eq("alert('done')")
        expect(control.input).to be_nil
      end
    end

    context "with camelCase keys" do
      let(:data) { { name: "Styled", additionalClasses: "btn-danger" } }

      it "converts them to snake_case" do
        expect(control.additional_classes).to eq("btn-danger")
      end
    end

    context "with unknown fields" do
      let(:data) { { name: "Custom", command: "M117", icon: "fa-fan", plugin: "foo" } }

      it "collects them in extra" do
        expect(control.extra).to eq({ icon: "fa-fan", plugin: "foo" })
      end
    end

    context "with only known fields" do
      let(:data) { { name: "Known", command: "M117" } }

      it "has no extra fields" do
        expect(control.extra).to be_nil
      end
    end
  end

  describe "#container?" do
    it "is true when the control has children" do
      expect(described_class.new(children: [])).to be_container
    end

    it "is false when the control has no children" do
      expect(described_class.new(command: "M107")).not_to be_container
    end
  end
end
