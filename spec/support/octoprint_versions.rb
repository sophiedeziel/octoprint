# typed: true
# frozen_string_literal: true

# The OctoPrint server versions the specs can record against and replay.
#
# Each version has its own server, configured with environment variables, its own VCR placeholders and its
# own cassette folder. 1.11 is the default and keeps the original cassette layout (`spec/cassettes/<name>`).
# Other versions record under `spec/cassettes/<version with underscores>/<name>`, e.g. `spec/cassettes/2_0/<name>`.
#
# Select a version with the `octoprint:` metadata:
#
#   describe "something", octoprint: "2.0", vcr: { cassette_name: "server_version/get" } do
#     # Talks to OCTOPRINT_HOST_2_0 and replays spec/cassettes/2_0/server_version/get.yml
#   end
module OctoprintVersions
  # Settings for one server version.
  Server = Struct.new(:version, :host_env, :api_key_env, :fallback_host_env, :fallback_api_key_env,
                      :default_host, :default_api_key, :host_placeholder, :api_key_placeholder,
                      :cassette_prefix, keyword_init: true) do
    def host
      ENV.fetch(host_env) { fallback_host_env ? ENV.fetch(fallback_host_env, default_host) : default_host }
    end

    def api_key
      ENV.fetch(api_key_env) do
        fallback_api_key_env ? ENV.fetch(fallback_api_key_env, default_api_key) : default_api_key
      end
    end

    def cassette_name(name)
      return name if cassette_prefix.nil? || name.start_with?("#{cassette_prefix}/")

      "#{cassette_prefix}/#{name}"
    end
  end

  DEFAULT = "1.11"

  SERVERS = {
    "1.11" => Server.new(
      version: "1.11",
      host_env: "OCTOPRINT_HOST_1_11",
      api_key_env: "OCTOPRINT_API_KEY_1_11",
      # The variables used before 2.0 support, still honoured for 1.11
      fallback_host_env: "OCTOPRINT_HOST",
      fallback_api_key_env: "OCTOPRINT_API_KEY",
      default_host: "http://octoprint.local",
      default_api_key: "fake_api_key",
      host_placeholder: "<HOST>",
      api_key_placeholder: "<API_KEY>",
      cassette_prefix: nil
    ),
    "2.0" => Server.new(
      version: "2.0",
      host_env: "OCTOPRINT_HOST_2_0",
      api_key_env: "OCTOPRINT_API_KEY_2_0",
      default_host: "http://octoprint2.local",
      default_api_key: "fake_2_0_api_key",
      host_placeholder: "<HOST_2_0>",
      api_key_placeholder: "<API_KEY_2_0>",
      cassette_prefix: "2_0" # VCR turns dots in cassette names into underscores
    )
  }.freeze

  module_function

  # @return [Array<String>] every supported server version
  def all
    SERVERS.keys
  end

  # @param version [String, nil] a server version, nil for the default one
  # @return [Server]
  def server(version = nil)
    SERVERS.fetch(version || DEFAULT) do
      raise ArgumentError, "Unknown OctoPrint version #{version.inspect} in spec metadata. Use one of #{all.inspect}"
    end
  end

  # Sensitive values to filter out of cassettes, longest value first, so a host that contains another
  # host (e.g. `http://octopi` and `http://octopi2`) is replaced by its own placeholder.
  #
  # @return [Array<Array(String, String)>] placeholder and real value pairs
  def sensitive_data
    SERVERS.values
           .flat_map { |s| [[s.host_placeholder, s.host], [s.api_key_placeholder, s.api_key]] }
           .sort_by { |(_placeholder, value)| -value.length }
  end

  # Example group DSL, available in every `describe`/`context`.
  module DSL
    # Defines one context per server version, each tagged with `octoprint: <version>`, and yields the version.
    # Use it to run the same expectations against every supported server:
    #
    #   on_octoprint_versions do |version|
    #     it_behaves_like "the version endpoint", version
    #   end
    #
    # @param versions [Array<String>] the versions to run, all of them by default
    def on_octoprint_versions(*versions, &block)
      versions = OctoprintVersions.all if versions.empty?
      versions.each do |version|
        OctoprintVersions.server(version)
        context("with OctoPrint #{version}", octoprint: version) { instance_exec(version, &block) }
      end
    end
  end
end
