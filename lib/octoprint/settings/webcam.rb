# typed: true
# frozen_string_literal: true

module Octoprint
  class Settings
    # Typed view of the webcam part of the OctoPrint settings.
    #
    # OctoPrint 1.9 added support for several webcams, provided by plugins. The
    # settings then list them under `webcam.webcams` and name the default one in
    # `webcam.defaultWebcam`. Older servers only expose the legacy flat keys
    # (`webcam.streamUrl`, `webcam.snapshotUrl`, ...). This class reads the
    # multi-webcam shape when it is present and falls back to the legacy keys.
    #
    # @example Get the webcam settings
    #   webcam = Octoprint::Settings.webcam
    #   puts webcam.stream_url if webcam.enabled
    #
    # @example Build it from settings you already fetched
    #   settings = Octoprint::Settings.get
    #   webcam = Octoprint::Settings::Webcam.from_settings(settings)
    #
    # @see https://docs.octoprint.org/en/master/api/settings.html
    class Webcam
      include AutoInitializable

      # @!attribute [r] enabled
      #   @return [Boolean] Whether the webcam is enabled in the OctoPrint settings
      auto_attr :enabled, type: T::Boolean, nilable: false

      # @!attribute [r] stream_url
      #   @return [String, nil] URL of the webcam stream. Can be relative to the OctoPrint host
      #     (e.g. "/webcam/?action=stream"). nil when no stream is configured.
      auto_attr :stream_url, type: String

      # @!attribute [r] snapshot_url
      #   @return [String, nil] URL to fetch a still image from the webcam. nil when not configured.
      auto_attr :snapshot_url, type: String

      # @!attribute [r] name
      #   @return [String, nil] Identifier of the webcam (OctoPrint 1.9+ only)
      auto_attr :name, type: String

      # @!attribute [r] display_name
      #   @return [String, nil] Human readable name of the webcam (OctoPrint 1.9+ only)
      auto_attr :display_name, type: String

      # @!attribute [r] flip_h
      #   @return [Boolean, nil] Whether the image should be flipped horizontally
      auto_attr :flip_h, type: T::Boolean

      # @!attribute [r] flip_v
      #   @return [Boolean, nil] Whether the image should be flipped vertically
      auto_attr :flip_v, type: T::Boolean

      # @!attribute [r] rotate90
      #   @return [Boolean, nil] Whether the image should be rotated 90° counter-clockwise
      auto_attr :rotate90, type: T::Boolean

      # @!attribute [r] stream_ratio
      #   @return [String, nil] Aspect ratio of the stream ("16:9" or "4:3")
      auto_attr :stream_ratio, type: String

      auto_initialize!

      # Builds the webcam settings from the hash returned by {Settings.get}.
      #
      # Uses the default webcam from the OctoPrint 1.9+ `webcams` list when there is
      # one (or the first webcam if the default can't be found), and only falls back to
      # the legacy `webcam` keys when the server has no `webcams` list. Empty URLs are
      # returned as nil. Works with the permission-filtered settings of OctoPrint 2.0: when
      # the `webcam` section or `webcam_enabled` is hidden, `enabled` is guessed from the stream URL.
      #
      # @example
      #   settings = Octoprint::Settings.get
      #   webcam = Octoprint::Settings::Webcam.from_settings(settings)
      #
      # @param settings [Hash] The settings hash, as returned by {Settings.get}
      # @return [Webcam]
      #: (Hash[Symbol, untyped] settings) -> Webcam
      def self.from_settings(settings)
        legacy = settings[:webcam] || {}
        camera = default_webcam(legacy)
        attributes = camera ? webcam_attributes(camera) : legacy_attributes(legacy)

        # OctoPrint 2.0 hides the webcam settings from users without the WEBCAM permission
        enabled = legacy[:webcam_enabled]
        enabled = attributes[:stream_url].present? if enabled.nil?

        T.unsafe(self).new(enabled: enabled, **attributes)
      end

      # Picks the default webcam from the OctoPrint 1.9+ `webcams` list.
      #
      # @param legacy [Hash] The `webcam` section of the settings
      # @return [Hash, nil] The default webcam's settings, or nil when there is no `webcams` list
      #: (Hash[Symbol, untyped] legacy) -> Hash[Symbol, untyped]?
      def self.default_webcam(legacy)
        webcams = Array(legacy[:webcams])
        webcams.find { |webcam| webcam[:name] == legacy[:default_webcam] } || webcams.first
      end

      # Reads the attributes of a webcam from the OctoPrint 1.9+ `webcams` list.
      #
      # The stream is only available for webcams that provide `compat` settings (or a
      # stream in their `extras`, like the classic webcam). `snapshotDisplay` is only
      # used when it is an HTTP URL, since plugins can put any text in it.
      #
      # @param camera [Hash] A webcam from the `webcams` list
      # @return [Hash] The attributes of the webcam
      #: (Hash[Symbol, untyped] camera) -> Hash[Symbol, untyped]
      def self.webcam_attributes(camera)
        compat = camera[:compat] || {}
        extras = camera[:extras] || {}
        snapshot_display = camera[:snapshot_display] if camera[:snapshot_display].to_s.match?(%r{\Ahttps?://}i)

        {
          stream_url: (compat[:stream] || extras[:stream]).presence,
          snapshot_url: (compat[:snapshot] || snapshot_display).presence,
          stream_ratio: compat[:stream_ratio] || extras[:stream_ratio],
          **camera.slice(:name, :display_name, :flip_h, :flip_v, :rotate90)
        }
      end

      # Reads the attributes from the legacy `webcam` keys of OctoPrint < 1.9.
      #
      # @param legacy [Hash] The `webcam` section of the settings
      # @return [Hash] The attributes of the webcam
      #: (Hash[Symbol, untyped] legacy) -> Hash[Symbol, untyped]
      def self.legacy_attributes(legacy)
        {
          stream_url: legacy[:stream_url].presence,
          snapshot_url: legacy[:snapshot_url].presence,
          **legacy.slice(:stream_ratio, :flip_h, :flip_v, :rotate90)
        }
      end

      private_class_method :default_webcam, :webcam_attributes, :legacy_attributes
    end
  end
end
