# typed: true
# frozen_string_literal: true

module Octoprint
  class Printer
    # Print head commands: jogging, homing and changing the feed rate.
    #
    # All commands except {.feedrate} may only be sent while the printer is operational and not printing.
    # Requires the +CONTROL+ permission.
    #
    # @example Jog the print head
    #   Octoprint::Printer::Printhead.jog(x: 10, y: -5, z: 0.02)
    #
    # @example Home the X and Y axes
    #   Octoprint::Printer::Printhead.home(axes: %w[x y])
    #
    # @example Set the feed rate to 105%
    #   Octoprint::Printer::Printhead.feedrate(105)
    #
    # @see https://docs.octoprint.org/en/master/api/printer.html#issue-a-print-head-command
    class Printhead < BaseResource
      extend T::Sig

      resource_path("/api/printer/printhead")

      # Issues a print head command.
      #
      # @param command [String] The command to issue: +jog+, +home+ or +feedrate+
      # @param options [Hash] Additional command parameters
      #
      # @example
      #   Octoprint::Printer::Printhead.issue_command(command: "home", options: { axes: ["z"] })
      #
      # @return [Boolean] true on success (204 No Content)
      # @raise [Octoprint::Exceptions::BadRequestError] if the parameters are invalid
      # @raise [Octoprint::Exceptions::ConflictError] if the printer is not operational or is printing
      sig { params(command: String, options: T::Hash[Symbol, T.untyped]).returns(T.untyped) }
      def self.issue_command(command:, options: {})
        post(params: { command: command }.merge(options))
      end

      # Jogs the print head by a relative amount, or to an absolute position, on one or more axes.
      #
      # @param x [Numeric, nil] Distance (or coordinate when +absolute+) to travel on the X axis, in mm
      # @param y [Numeric, nil] Distance (or coordinate when +absolute+) to travel on the Y axis, in mm
      # @param z [Numeric, nil] Distance (or coordinate when +absolute+) to travel on the Z axis, in mm
      # @param absolute [Boolean, nil] Move to absolute coordinates instead of relative amounts
      # @param speed [Integer, false, nil] Speed in mm/min. Defaults to the profile's minimum axis speed;
      #   +false+ sends no speed at all
      #
      # @example Relative jog
      #   Octoprint::Printer::Printhead.jog(x: 10, y: -5, z: 0.02)
      #
      # @example Absolute move at a given speed
      #   Octoprint::Printer::Printhead.jog(x: 100, y: 100, absolute: true, speed: 3000)
      #
      # @return [Boolean] true on success (204 No Content)
      # @raise [Octoprint::Exceptions::BadRequestError] if an amount is invalid
      # @raise [Octoprint::Exceptions::ConflictError] if the printer is not operational or is printing
      sig do
        params(
          x: T.nilable(Numeric),
          y: T.nilable(Numeric),
          z: T.nilable(Numeric),
          absolute: T.nilable(T::Boolean),
          speed: T.nilable(T.any(Integer, FalseClass))
        ).returns(T.untyped)
      end
      def self.jog(x: nil, y: nil, z: nil, absolute: nil, speed: nil) # rubocop:disable Naming/MethodParameterName
        issue_command(command: "jog", options: { x: x, y: y, z: z, absolute: absolute, speed: speed }.compact)
      end

      # Homes the print head on the given axes.
      #
      # @param axes [Array<String, Symbol>] The axes to home, one or more of +x+, +y+ and +z+. Defaults to all three.
      #
      # @example Home all axes
      #   Octoprint::Printer::Printhead.home
      #
      # @example Home X and Y only
      #   Octoprint::Printer::Printhead.home(axes: %w[x y])
      #
      # @return [Boolean] true on success (204 No Content)
      # @raise [Octoprint::Exceptions::BadRequestError] if an invalid axis is given
      # @raise [Octoprint::Exceptions::ConflictError] if the printer is not operational or is printing
      sig { params(axes: T::Array[T.any(String, Symbol)]).returns(T.untyped) }
      def self.home(axes: %w[x y z])
        issue_command(command: "home", options: { axes: axes.map(&:to_s) })
      end

      # Changes the feed rate factor applied to the movements of the axes.
      #
      # @param factor [Numeric] Percentage between 50 and 200 as an integer (+50+..+200+) or float (+0.5+..+2.0+)
      #
      # @example Using a percentage
      #   Octoprint::Printer::Printhead.feedrate(105)
      #
      # @example Using a float
      #   Octoprint::Printer::Printhead.feedrate(1.05)
      #
      # @return [Boolean] true on success (204 No Content)
      # @raise [Octoprint::Exceptions::BadRequestError] if the factor is out of range
      sig { params(factor: Numeric).returns(T.untyped) }
      def self.feedrate(factor)
        issue_command(command: "feedrate", options: { factor: factor })
      end
    end
  end
end
