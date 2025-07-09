# typed: true
# frozen_string_literal: true

module Octoprint
  # OctoPrint Util API
  # @see https://docs.octoprint.org/en/1.11.2/api/util.html
  class Util < BaseResource
    extend T::Sig
    include AutoInitializable
    include Deserializable

    resource_path("/api/util")

    auto_attr :result, type: String, nilable: true
    auto_attr :exists, type: T::Boolean, nilable: true
    auto_attr :status, type: String, nilable: true
    auto_attr :extra, type: Hash

    auto_initialize!

    deserialize_config do
      transform do |data|
        data
      end
    end

    # Test file system paths
    #
    # @param [String] path Mandatory file system path
    # @param [String] check_type Optional (file/directory)
    # @param [String] check_access Optional permissions check
    # @param [Boolean] allow_create_dir Optional directory creation flag
    # @param [Boolean] check_writable_dir Optional directory writability test
    # @return [Util]
    sig do
      params(
        path: String,
        check_type: T.nilable(String),
        check_access: T.nilable(String),
        allow_create_dir: T.nilable(T::Boolean),
        check_writable_dir: T.nilable(T::Boolean)
      ).returns(Util)
    end
    def self.test_path(path:, check_type: nil, check_access: nil, allow_create_dir: nil, check_writable_dir: nil)
      params = { command: "path", path: path }
      params[:check_type] = check_type if check_type
      params[:check_access] = check_access if check_access
      params[:allow_create_dir] = allow_create_dir unless allow_create_dir.nil?
      params[:check_writable_dir] = check_writable_dir unless check_writable_dir.nil?

      response = post(path: "#{@path}/test", params: params)
      deserialize(response)
    end

    # Test URL connectivity
    #
    # @param [String] url Mandatory URL to test
    # @param [String] method Optional HTTP method (default HEAD)
    # @param [Integer] timeout Optional timeout in seconds (default 3)
    # @param [Integer] status Optional expected status code
    # @param [String] auth_user Optional basic auth username
    # @param [String] auth_pass Optional basic auth password
    # @param [String] auth_digest Optional digest auth
    # @param [String] auth_bearer Optional bearer token
    # @param [String] content_type_whitelist Optional content type filter
    # @param [String] content_type_blacklist Optional content type exclusion
    # @return [Util]
    sig do
      params(
        url: String,
        method: T.nilable(String),
        timeout: T.nilable(Integer),
        status: T.nilable(Integer),
        auth_user: T.nilable(String),
        auth_pass: T.nilable(String),
        auth_digest: T.nilable(String),
        auth_bearer: T.nilable(String),
        content_type_whitelist: T.nilable(String),
        content_type_blacklist: T.nilable(String)
      ).returns(Util)
    end
    def self.test_url(url:, method: nil, timeout: nil, status: nil, auth_user: nil, auth_pass: nil,
                      auth_digest: nil, auth_bearer: nil, content_type_whitelist: nil, content_type_blacklist: nil)
      # rubocop:enable Metrics/ParameterLists
      options = {
        method: method, timeout: timeout, status: status,
        auth_user: auth_user, auth_pass: auth_pass, auth_digest: auth_digest, auth_bearer: auth_bearer,
        content_type_whitelist: content_type_whitelist, content_type_blacklist: content_type_blacklist
      }.compact
      params = build_url_test_params(url, options)
      response = post(path: "#{@path}/test", params: params)
      deserialize(response)
    end

    private_class_method def self.build_url_test_params(url, options)
      { command: "url", url: url }.merge(options.compact)
    end

    # Test server connectivity
    #
    # @param [String] host Mandatory hostname or IP address
    # @param [Integer] port Mandatory port number
    # @param [String] protocol Optional protocol (default TCP)
    # @param [Float] timeout Optional timeout in seconds (default 3.05)
    # @return [Util]
    sig do
      params(
        host: String,
        port: Integer,
        protocol: T.nilable(String),
        timeout: T.nilable(Float)
      ).returns(Util)
    end
    def self.test_server(host:, port:, protocol: nil, timeout: nil)
      params = { command: "server", host: host, port: port }
      params[:protocol] = protocol if protocol
      params[:timeout] = timeout if timeout

      response = post(path: "#{@path}/test", params: params)
      deserialize(response)
    end

    # Test DNS hostname resolution
    #
    # @param [String] name Mandatory hostname to resolve
    # @return [Util]
    sig { params(name: String).returns(Util) }
    def self.test_resolution(name:)
      params = { command: "resolution", name: name }

      response = post(path: "#{@path}/test", params: params)
      deserialize(response)
    end

    # Test network address
    #
    # @param [String] address Optional address (defaults to client address)
    # @return [Util]
    sig { params(address: T.nilable(String)).returns(Util) }
    def self.test_address(address: nil)
      params = { command: "address" }
      params[:address] = address if address

      response = post(path: "#{@path}/test", params: params)
      deserialize(response)
    end
  end
end
