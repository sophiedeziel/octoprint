# typed: true
# frozen_string_literal: true

module Octoprint
  # The OctoPrint API versions the gem speaks, and the features that need a specific one.
  #
  # OctoPrint 2.0 added [API versioning](https://docs.octoprint.org/en/dev/api/general.html#api-versioning):
  # a client that sends `X-OctoPrint-Api-Version: 2.0.0` gets the 2.0 response shapes, and a client that sends
  # nothing keeps the 1.x shapes. OctoPrint 1.11 ignores the header.
  #
  # Pick the version with the `api_version:` option of {Client#initialize} or {Octoprint.configure}:
  # - `"1.11"` (default): the 1.x API. No header, works with 1.11 and 2.0 servers.
  # - `"2.0"`: the 2.0 API. Sends the header. Only use it with OctoPrint 2.0 servers.
  # - `:auto`: asks the server for its version once, then uses the latest API both sides support.
  #
  # @example Compare a server version
  #   Octoprint::ApiVersion.parse("2.0.0rc7") >= Octoprint::ApiVersion::MINIMUM_2_0 # => true
  module ApiVersion
    # The 1.x API, as documented for OctoPrint 1.11
    V1_11 = Gem::Version.new("1.11")

    # The OctoPrint 2.0 API
    V2_0 = Gem::Version.new("2.0")

    # The `api_version:` values a client accepts, and the API version each one selects
    REQUESTABLE = { "1.11" => V1_11, "2.0" => V2_0 }.freeze

    # The `api_version:` used when none is given
    DEFAULT = "1.11"

    # Detects the server version and uses the latest API both sides support
    AUTO = :auto

    # Lowest server version that speaks the 2.0 API. Compares lower than every 2.0 pre-release
    # (`2.0.0rc7`, `2.0.0.dev12`), which `Gem::Version.new("2.0.0")` would not.
    MINIMUM_2_0 = Gem::Version.new("2.0.0.a")

    # Value of the `X-OctoPrint-Api-Version` header for each API version that needs one
    HEADER_VALUES = { V2_0 => "2.0.0" }.freeze

    # Name of the header that selects the API version on OctoPrint 2.0 and later
    HEADER = "X-OctoPrint-Api-Version"

    # Features that need a specific API version, and the lowest API version that has them
    FEATURES = {
      connectors: V2_0,
      printer_storage: V2_0,
      refresh_thumbnails: V2_0,
      cross_storage_move: V2_0,
      reauth_required: V2_0
    }.freeze

    class << self
      # Parses a server version string as reported by `GET /api/version`.
      #
      # Drops a local build suffix (`1.11.8+g1a2b3c`, `2.0.0.dev12+gabc.dirty`), which `Gem::Version` can't parse.
      #
      # @example
      #   Octoprint::ApiVersion.parse("2.0.0rc7") # => Gem::Version "2.0.0rc7"
      #
      # @param version [String] The server version, e.g. `"1.11.8"` or `"2.0.0rc7"`
      # @return [Gem::Version]
      # @raise [ArgumentError] if the version can't be parsed
      #: (String) -> Gem::Version
      def parse(version)
        Gem::Version.new(version.to_s.split("+").first.to_s.strip)
      rescue ArgumentError
        raise ArgumentError, "Can't parse the OctoPrint version #{version.inspect}"
      end

      # The latest API version the gem supports for a server version.
      #
      # @param server_version [Gem::Version] The server's version
      # @return [Gem::Version] {V2_0} for OctoPrint 2.0 and later (pre-releases included), {V1_11} otherwise
      #: (Gem::Version) -> Gem::Version
      def for_server(server_version)
        server_version >= MINIMUM_2_0 ? V2_0 : V1_11
      end

      # Whether an API version answers with the 1.x response shapes.
      #
      # @param api_version [Gem::Version]
      # @return [Boolean]
      #: (Gem::Version) -> bool
      def legacy?(api_version)
        api_version < V2_0
      end

      # The `X-OctoPrint-Api-Version` header value for an API version
      #
      # @param api_version [Gem::Version]
      # @return [String, nil] nil when the API version doesn't need the header
      #: (Gem::Version) -> String?
      def header_value(api_version)
        HEADER_VALUES[api_version]
      end

      # The lowest API version that has a feature.
      #
      # @param feature [Symbol] A key of {FEATURES}
      # @return [Gem::Version]
      # @raise [ArgumentError] for an unknown feature
      #: (Symbol) -> Gem::Version
      def required_for(feature)
        FEATURES.fetch(feature) do
          raise ArgumentError, "Unknown feature #{feature.inspect}. Known features: #{FEATURES.keys.inspect}"
        end
      end
    end
  end
end
