# typed: true
# frozen_string_literal: true

require "erb"
require "faraday"

module Octoprint
  # Timelapse API: list, delete and render timelapses, and change the timelapse config.
  #
  # {.list}, {.delete_file} and {.update_config} return the server's timelapse list:
  # the current {Config}, the {Rendered} timelapse files and, when requested with
  # +unrendered: true+, the {Unrendered} timelapse jobs.
  #
  # Permissions: +TIMELAPSE_LIST+ ({.list}), +TIMELAPSE_DELETE+ ({.delete_file}),
  # +TIMELAPSE_MANAGE_UNRENDERED+ ({.render}, {.delete_unrendered}) and
  # +TIMELAPSE_ADMIN+ ({.update_config}).
  #
  # @example List rendered timelapses
  #   timelapse = Octoprint::Timelapse.list
  #   timelapse.config.type # => "off"
  #   timelapse.files.each { |file| puts "#{file.name} (#{file.size})" }
  #
  # @example Render every unrendered timelapse that isn't being processed
  #   Octoprint::Timelapse.list(unrendered: true).unrendered.each do |job|
  #     Octoprint::Timelapse.render(name: job.name) unless job.processing
  #   end
  #
  # @example Take a snapshot every 10 seconds of the next print
  #   Octoprint::Timelapse.update_config(type: "timed", interval: 10, fps: 30, save: true)
  #
  # @see https://docs.octoprint.org/en/1.11.2/api/timelapse.html
  class Timelapse < BaseResource
    extend T::Sig
    include AutoInitializable
    include Deserializable

    resource_path("/api/timelapse")

    # Timelapse types accepted by {.update_config}
    TYPES = T.let(%w[off zchange timed].freeze, T::Array[String])

    # @!attribute [r] config
    #   @return [Timelapse::Config] The current timelapse configuration
    auto_attr :config, type: Config

    # @!attribute [r] enabled
    #   @return [Boolean] Whether timelapses are enabled in the webcam settings
    auto_attr :enabled, type: Types::Boolean

    # @!attribute [r] files
    #   @return [Array<Timelapse::Rendered>] The rendered timelapse files
    auto_attr :files, type: Rendered, array: true

    # @!attribute [r] unrendered
    #   @return [Array<Timelapse::Unrendered>, nil] The unrendered timelapse jobs, only present when requested
    auto_attr :unrendered, type: Unrendered, array: true

    # @!attribute [r] extra
    #   @return [Hash, nil] Any additional fields returned by the API
    auto_attr :extra, type: Hash

    auto_initialize!

    deserialize_config do
      nested :config, Config
      array :files, Rendered
      array :unrendered, Unrendered
    end

    class << self
      extend T::Sig

      # Retrieves the list of timelapses and the current timelapse config.
      #
      # @param unrendered [Boolean] Also list the unrendered timelapses
      # @param force [Boolean] Bypass the server's timelapse list cache
      #
      # @example
      #   timelapse = Octoprint::Timelapse.list(unrendered: true)
      #   timelapse.files.map(&:name)      # => ["benchy_20261115.mp4"]
      #   timelapse.unrendered.map(&:name) # => ["cube_20261115"]
      #
      # @return [Timelapse] The timelapse list
      sig { params(unrendered: T::Boolean, force: T::Boolean).returns(Timelapse) }
      def list(unrendered: false, force: false)
        fetch_resource(options: query(unrendered: unrendered, force: force))
      end

      # Deletes a rendered timelapse file.
      #
      # @param filename [String] The name of the timelapse file
      # @param unrendered [Boolean] Also list the unrendered timelapses in the returned list
      #
      # @example
      #   Octoprint::Timelapse.delete_file(filename: "benchy_20261115.mp4")
      #
      # @return [Timelapse] The updated timelapse list
      sig { params(filename: String, unrendered: T::Boolean).returns(Timelapse) }
      def delete_file(filename:, unrendered: false)
        response = delete(path: with_query("#{@path}/#{escape(filename)}", query(unrendered: unrendered)))
        deserialize(response)
      end

      # Issues a command for an unrendered timelapse.
      #
      # @param name [String] The name of the unrendered timelapse job
      # @param command [String] The command to issue. OctoPrint only supports +render+
      #
      # @example
      #   Octoprint::Timelapse.issue_unrendered_command(name: "cube_20261115", command: "render")
      #
      # @return [Boolean] true on success (204 No Content)
      # @raise [Octoprint::Exceptions::ConflictError] if the printer is printing or paused
      sig { params(name: String, command: String).returns(T.untyped) }
      def issue_unrendered_command(name:, command:)
        post(path: "#{@path}/unrendered/#{escape(name)}", params: { command: command })
      end

      # Renders an unrendered timelapse. Rendering happens in the background on the server.
      #
      # @param name [String] The name of the unrendered timelapse job
      #
      # @example
      #   Octoprint::Timelapse.render(name: "cube_20261115")
      #
      # @return [Boolean] true on success (204 No Content)
      # @raise [Octoprint::Exceptions::ConflictError] if the printer is printing or paused
      sig { params(name: String).returns(T.untyped) }
      def render(name:)
        issue_unrendered_command(name: name, command: "render")
      end

      # Deletes an unrendered timelapse and its snapshots.
      #
      # @param name [String] The name of the unrendered timelapse job
      #
      # @example
      #   Octoprint::Timelapse.delete_unrendered(name: "cube_20261115")
      #
      # @return [Boolean] true on success (204 No Content)
      sig { params(name: String).returns(T.untyped) }
      def delete_unrendered(name:)
        delete(path: "#{@path}/unrendered/#{escape(name)}")
      end

      # Changes the timelapse config used for the next print.
      #
      # Options OctoPrint doesn't use for the given +type+ are ignored by the server.
      # Settings left out fall back to OctoPrint's defaults (no post roll, 25 fps,
      # always render after the print).
      #
      # @param type [String] +off+, +zchange+ (snapshot on Z change) or +timed+ (snapshot on an interval)
      # @param post_roll [Integer, nil] Post roll in seconds
      # @param fps [Integer, nil] Frames per second of the rendered video
      # @param interval [Integer, nil] Seconds between snapshots (+timed+ only)
      # @param retraction_z_hop [Numeric, nil] Retraction Z hop to ignore when detecting Z changes (+zchange+ only)
      # @param min_delay [Numeric, nil] Minimum seconds between snapshots (+zchange+ only)
      # @param render_after_print [String, nil] When to render after a print:
      #   +always+, +success+, +failure+ or +never+
      # @param save [Boolean] Persist the config across server restarts (requires admin rights)
      # @param unrendered [Boolean] Also list the unrendered timelapses in the returned list
      #
      # @example Snapshot on every layer change, rendered only for successful prints
      #   Octoprint::Timelapse.update_config(type: "zchange", retraction_z_hop: 0.4, render_after_print: "success")
      #
      # @example Turn timelapses off
      #   Octoprint::Timelapse.update_config(type: "off")
      #
      # @return [Timelapse] The updated timelapse list
      # @raise [ArgumentError] if the type isn't one of {TYPES}
      # @raise [Octoprint::Exceptions::BadRequestError] if a setting is invalid
      sig do
        params(
          type: String,
          post_roll: T.nilable(Integer),
          fps: T.nilable(Integer),
          interval: T.nilable(Integer),
          retraction_z_hop: T.nilable(Numeric),
          min_delay: T.nilable(Numeric),
          render_after_print: T.nilable(String),
          save: T::Boolean,
          unrendered: T::Boolean
        ).returns(Timelapse)
      end
      def update_config(type:, post_roll: nil, fps: nil, interval: nil, retraction_z_hop: nil, min_delay: nil,
                        render_after_print: nil, save: false, unrendered: false)
        raise ArgumentError, "type must be one of #{TYPES.join(", ")}" unless TYPES.include?(type)

        params = {
          type: type,
          postRoll: post_roll,
          fps: fps,
          interval: interval,
          retractionZHop: retraction_z_hop,
          minDelay: min_delay,
          renderAfterPrint: render_after_print
        }.compact
        params[:save] = true if save

        response = post(path: with_query(@path, query(unrendered: unrendered)), params: params)
        deserialize(response)
      end

      private

      sig { params(flags: T::Boolean).returns(T::Hash[Symbol, T::Boolean]) }
      def query(**flags)
        flags.select { |_flag, value| value }
      end

      sig { params(path: String, options: T::Hash[Symbol, T.untyped]).returns(String) }
      def with_query(path, options)
        return path if options.empty?

        "#{path}?#{Faraday::Utils.build_query(options)}"
      end

      # Percent-encodes a name for use as a path segment. Timelapse names keep the
      # characters of the printed file's name, including spaces and "#".
      sig { params(name: String).returns(String) }
      def escape(name)
        ERB::Util.url_encode(name)
      end
    end
  end
end
