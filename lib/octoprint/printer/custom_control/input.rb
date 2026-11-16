# typed: true
# frozen_string_literal: true

module Octoprint
  class Printer
    class CustomControl
      # An input parameter of a custom control.
      #
      # @example
      #   input = Octoprint::Printer::Command.custom_controls.first.children.first.input.first
      #   input.name       # => "Speed (0-255)"
      #   input.parameter  # => "speed"
      #   input.default    # => 255
      #   input.slider     # => { min: 0, max: 255 }
      #
      # @see https://docs.octoprint.org/en/master/features/custom_controls.html
      class Input
        include AutoInitializable
        include Deserializable

        # @!attribute [r] name
        #   @return [String, nil] Name to display for the input field
        auto_attr :name, type: String

        # @!attribute [r] parameter
        #   @return [String, nil] Placeholder name used in the control's command(s)
        auto_attr :parameter, type: String

        # @!attribute [r] default
        #   @return [Object, nil] Default value of the input field
        auto_attr :default, type: T.untyped

        # @!attribute [r] slider
        #   @return [Hash, nil] Slider settings (+min+, +max+, +step+) when rendered as a slider
        auto_attr :slider, type: Hash

        # @!attribute [r] extra
        #   @return [Hash, nil] Any additional fields returned by the API
        auto_attr :extra, type: Hash

        auto_initialize!
      end
    end
  end
end
