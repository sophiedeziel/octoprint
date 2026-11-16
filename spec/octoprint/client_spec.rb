# typed: true
# frozen_string_literal: true

require "webmock/rspec/matchers"

RSpec.describe Octoprint::Client do
  include_context "with default Octoprint config"

  it "raises when host is missing" do
    expect do
      described_class.new(host: nil, api_key: api_key)
    end.to raise_error Octoprint::Exceptions::MissingCredentialsError
  end

  it "raises when api_key is missing" do
    expect do
      described_class.new(host: host, api_key: nil)
    end.to raise_error Octoprint::Exceptions::MissingCredentialsError
  end

  it "accepts a URI as host" do
    client = described_class.new(host: URI("http://octopi.local"), api_key: api_key)

    expect(client.client.url_prefix.host).to eq "octopi.local"
  end

  describe "timeouts" do
    it "defaults to a 2 seconds open timeout and a 3 seconds timeout" do
      client = described_class.new(host: host, api_key: api_key)

      expect(client).to have_attributes(open_timeout: 2, timeout: 3)
      expect(client.client.options).to have_attributes(open_timeout: 2, timeout: 3)
    end

    it "passes custom timeouts to Faraday" do
      client = described_class.new(host: host, api_key: api_key, open_timeout: 0.5, timeout: 10)

      expect(client.client.options).to have_attributes(open_timeout: 0.5, timeout: 10)
    end

    it "leaves nil timeouts to the adapter defaults" do
      client = described_class.new(host: host, api_key: api_key, open_timeout: nil, timeout: nil)

      expect(client.client.options).to have_attributes(open_timeout: nil, timeout: nil)
    end

    it "passes the timeouts to the multipart client" do
      client = described_class.new(host: host, api_key: api_key, open_timeout: 1, timeout: 30)

      expect(client.send(:new_client, multipart: true).options).to have_attributes(open_timeout: 1, timeout: 30)
    end
  end

  describe "connection errors" do
    let(:client) { described_class.new(host: host, api_key: api_key) }

    it "raises a TimeoutError when the server doesn't respond in time" do
      allow(client.client).to receive(:get).and_raise(Faraday::TimeoutError, "Net::ReadTimeout")

      expect { client.request("/api/version") }
        .to raise_error(Octoprint::Exceptions::TimeoutError, "Net::ReadTimeout")
    end

    it "raises a TimeoutError when the connection doesn't open in time" do
      allow(client.client).to receive(:get).and_raise(Faraday::ConnectionFailed.new(Net::OpenTimeout.new("expired")))

      expect { client.request("/api/version") }.to raise_error(Octoprint::Exceptions::TimeoutError)
    end

    it "raises a ConnectionError when the server can't be reached" do
      allow(client.client).to receive(:get)
        .and_raise(Faraday::ConnectionFailed.new(Errno::ECONNREFUSED.new("connect(2)")))

      expect { client.request("/api/version") }.to raise_error(Octoprint::Exceptions::ConnectionError, /refused/)
    end

    it "raises a ConnectionError on SSL failures" do
      allow(client.client).to receive(:get).and_raise(Faraday::SSLError, "certificate verify failed")

      expect { client.request("/api/version") }
        .to raise_error(Octoprint::Exceptions::ConnectionError, "certificate verify failed")
    end

    it "raises a TimeoutError from multipart requests" do
      multipart_client = client.send(:new_client, multipart: true)
      allow(client).to receive(:new_client).with(multipart: true).and_return(multipart_client)
      allow(multipart_client).to receive(:post).and_raise(Faraday::TimeoutError)

      expect { client.request("/api/files/local", http_method: :post, body: {}, options: { force_multipart: true }) }
        .to raise_error(Octoprint::Exceptions::TimeoutError)
    end
  end

  describe "#use" do
    let(:client) do
      described_class.new(host: host, api_key: api_key)
    end

    before do
      Octoprint.configure(host: "http://192.168.0.1", api_key: "a key")
    end

    it "makes all requests in the block as the client" do
      client.use do
        expect(Octoprint.client.host).to eq client.host
      end
    end

    it "sets back the configured client after the block" do
      client.use do
        # Do some operations
      end
      expect(Octoprint.client.host).to eq "http://192.168.0.1"
    end

    it "sets back the configured client after the block after exceptions" do
      client.use { raise StandardError }
    rescue StandardError
      expect(Octoprint.client.host).to eq "http://192.168.0.1"
    end

    it "has config that is not shared with threads" do
      client_in_thread = nil
      Thread.new do
        client_in_thread = Octoprint.client
      end.join
      expect(client_in_thread).to be_nil
    end
  end

  describe "#request" do
    let(:client) { described_class.new(host: host, api_key: api_key) }
    let(:faraday_client) { instance_double(Faraday::Connection) }
    let(:response) { instance_double(Faraday::Response, status: 200, body: '{"key":"value"}') }

    before do
      allow(client).to receive(:client).and_return(faraday_client)
      allow(faraday_client).to receive(:get).and_return(response)
    end

    it "handles JSON parsing errors gracefully" do
      invalid_response = instance_double(Faraday::Response, status: 200, body: "invalid json")
      allow(faraday_client).to receive(:get).and_return(invalid_response)

      expect { client.request("/test") }.to raise_error(JSON::ParserError)
    end

    it "returns the body as a hash" do
      result = client.request("/test")
      expect(result).to eq({ key: "value" })
    end
  end

  describe "parse_response and transform_keys_recursively" do
    let(:client) { described_class.new(host: host, api_key: api_key) }

    it "transforms keys in hash responses" do
      response = instance_double(Faraday::Response, body: '{"camelCase":"value"}')
      result = client.send(:parse_response, response)
      expect(result).to eq({ camel_case: "value" })
    end

    it "transforms keys in array responses" do
      response = instance_double(Faraday::Response, body: '[{"camelCase":"value1"},{"anotherKey":"value2"}]')
      result = client.send(:parse_response, response)
      expect(result).to eq([{ camel_case: "value1" }, { another_key: "value2" }])
    end

    it "handles primitive values in arrays" do
      response = instance_double(Faraday::Response, body: '["string", 123, true, null]')
      result = client.send(:parse_response, response)
      expect(result).to eq(["string", 123, true, nil])
    end

    it "handles nested structures" do
      response = instance_double(Faraday::Response, body: '[{"camelCase":{"nestedKey":"value"}}]')
      result = client.send(:parse_response, response)
      expect(result).to eq([{ camel_case: { nested_key: "value" } }])
    end
  end

  describe "private methods" do
    let(:client) { described_class.new(host: host, api_key: api_key) }

    describe "#new_client" do
      it "handles nil api_key gracefully" do
        # Create a client instance and test the private method behavior
        allow(client).to receive(:api_key).and_return(nil)

        faraday_client = client.send(:new_client)
        expect(faraday_client).to be_a(Faraday::Connection)
        # The Authorization header should not be set when api_key is nil
        expect(faraday_client.headers["Authorization"]).to be_nil
      end

      it "creates multipart client" do
        multipart_client = client.send(:new_client, multipart: true)
        expect(multipart_client).to be_a(Faraday::Connection)
        expect(multipart_client.headers["Content-Type"]).to eq("multipart/form-data")
      end
    end

    describe "#request_with_client" do
      it "exercises multipart detection with Faraday::UploadIO" do
        # Create a mock upload IO to trigger the multipart branch
        upload_io = instance_double(Faraday::UploadIO)
        allow(upload_io).to receive(:is_a?).with(Faraday::UploadIO).and_return(true)

        body = { file: upload_io }

        # Mock the clients
        regular_client = {}
        multipart_client = {}
        response = {}

        allow(client).to receive(:client).and_return(regular_client)
        allow(client).to receive(:new_client).with(multipart: true).and_return(multipart_client)
        allow(multipart_client).to receive(:post).and_return(response)

        client.send(:request_with_client, :post, "/upload", body, {})

        expect(client).to have_received(:new_client).with(multipart: true)
      end
    end

    describe "#process_error" do
      it "handles unknown HTTP status codes" do
        # Mock a response with an unknown status code (not in the errors hash)
        response = instance_double(
          Faraday::Response,
          status: 418, # I'm a teapot - not in the standard error mapping
          body: '{"error":"Unknown error"}'
        )

        expect do
          client.send(:process_error, response)
        end.to raise_error(Octoprint::Exceptions::UnknownError, "[418] Unknown error")
      end

      def error_response(status:, body:, reason_phrase: nil)
        instance_double(Faraday::Response, status: status, body: body, reason_phrase: reason_phrase)
      end

      it "falls back to the raw body when the JSON body has no error key" do
        response = error_response(status: 404, body: '{"message":"nope"}')

        expect { client.send(:process_error, response) }
          .to raise_error(Octoprint::Exceptions::NotFoundError, '[404] {"message":"nope"}')
      end

      it "falls back to the raw body when the error key isn't a message" do
        response = error_response(status: 400, body: '{"error":null}')

        expect { client.send(:process_error, response) }
          .to raise_error(Octoprint::Exceptions::BadRequestError, '[400] {"error":null}')
      end

      it "falls back to the raw body when the body isn't JSON" do
        response = error_response(status: 500, body: "<html><body>Bad Gateway</body></html>\n")

        expect { client.send(:process_error, response) }
          .to raise_error(Octoprint::Exceptions::InternalServerError, "[500] <html><body>Bad Gateway</body></html>")
      end

      it "falls back to the raw body when the JSON body isn't an object" do
        response = error_response(status: 409, body: '["conflict"]')

        expect { client.send(:process_error, response) }
          .to raise_error(Octoprint::Exceptions::ConflictError, '[409] ["conflict"]')
      end

      it "truncates a long raw body" do
        response = error_response(status: 502, body: "x" * 1000)

        expect { client.send(:process_error, response) }.to raise_error(Octoprint::Exceptions::UnknownError) do |error|
          expect(error.message.length).to eq("[502] ".length + described_class::MAX_ERROR_BODY_LENGTH)
          expect(error.message).to end_with("...")
        end
      end

      it "falls back to the reason phrase when the body is empty" do
        response = error_response(status: 403, body: "", reason_phrase: "FORBIDDEN")

        expect { client.send(:process_error, response) }
          .to raise_error(Octoprint::Exceptions::AuthenticationError, "[403] FORBIDDEN")
      end

      it "falls back to the status when the body and the reason phrase are empty" do
        response = error_response(status: 502, body: nil, reason_phrase: nil)

        expect { client.send(:process_error, response) }
          .to raise_error(Octoprint::Exceptions::UnknownError, "[502] HTTP 502")
      end
    end
  end

  describe "API versions" do
    include WebMock::API
    include WebMock::Matchers

    let(:base) { "http://test.local" }
    let(:version_body) { ->(server) { { status: 200, body: { server: server, text: "OctoPrint #{server}" }.to_json } } }

    after { WebMock.reset! }

    def new_client(api_version = nil)
      return described_class.new(host: base, api_key: "key") if api_version.nil?

      described_class.new(host: base, api_key: "key", api_version: api_version)
    end

    def header_sent?(request)
      request.headers.key?("X-Octoprint-Api-Version")
    end

    describe "api_version: option" do
      it "defaults to the 1.11 API" do
        client = new_client

        expect(client.requested_api_version).to eq "1.11"
        expect(client.api_version).to eq Octoprint::ApiVersion::V1_11
        expect(client).to be_legacy_api
      end

      it "speaks the 2.0 API when asked to" do
        client = new_client("2.0")

        expect(client.api_version).to eq Octoprint::ApiVersion::V2_0
        expect(client).not_to be_legacy_api
      end

      ["2.0.0", "1.9", :legacy, nil].each do |value|
        it "rejects #{value.inspect}" do
          expect { new_client(value || "") }
            .to raise_error(ArgumentError, /Unknown api_version .*Use one of "1.11", "2.0", :auto/)
        end
      end

      it "never asks a pinned client's server for its version" do
        client = new_client("2.0")
        client.api_version

        expect(client.server_version).to be_nil
      end
    end

    describe "X-OctoPrint-Api-Version header" do
      it "isn't sent with the 1.11 API" do
        stub = stub_request(:get, "#{base}/api/job").with { |request| !header_sent?(request) }.to_return(body: "{}")

        new_client.request("/api/job")

        expect(stub).to have_been_requested
      end

      it "sends 2.0.0 with the 2.0 API" do
        stub = stub_request(:get, "#{base}/api/job")
               .with(headers: { "X-OctoPrint-Api-Version" => "2.0.0" }).to_return(body: "{}")

        new_client("2.0").request("/api/job")

        expect(stub).to have_been_requested
      end

      it "is sent with multipart uploads" do
        stub = stub_request(:post, "#{base}/api/files/local")
               .with(headers: { "X-OctoPrint-Api-Version" => "2.0.0" }).to_return(body: "{}")

        new_client("2.0").request("/api/files/local", http_method: :post, body: { print: true },
                                                      options: { force_multipart: true })

        expect(stub).to have_been_requested
      end

      it "keeps the caller's headers" do
        stub = stub_request(:post, "#{base}/api/job")
               .with(headers: { "X-OctoPrint-Api-Version" => "2.0.0", "X-Custom" => "yes" }).to_return(status: 204)

        new_client("2.0").request("/api/job", http_method: :post, body: {}, headers: { "X-Custom" => "yes" })

        expect(stub).to have_been_requested
      end
    end

    describe "api_version: :auto" do
      it "doesn't reach the server before the first request" do
        new_client(:auto)

        expect(a_request(:any, /test.local/)).not_to have_been_made
      end

      it "detects the server version without the header, once" do
        detection = stub_request(:get, "#{base}/api/version").with { |request| !header_sent?(request) }
                                                             .to_return(version_body.call("2.0.0rc7"))
        job = stub_request(:get, "#{base}/api/job").with(headers: { "X-OctoPrint-Api-Version" => "2.0.0" })
                                                   .to_return(body: "{}")
        client = new_client(:auto)

        2.times { client.request("/api/job") }

        expect(detection).to have_been_requested.once
        expect(job).to have_been_requested.twice
        expect(client.server_version).to eq Gem::Version.new("2.0.0rc7")
        expect(client.api_version).to eq Octoprint::ApiVersion::V2_0
      end

      it "speaks the 1.11 API with an OctoPrint 1.x server" do
        stub_request(:get, "#{base}/api/version").to_return(version_body.call("1.11.8"))
        job = stub_request(:get, "#{base}/api/job").with { |request| !header_sent?(request) }.to_return(body: "{}")
        client = new_client(:auto)

        client.request("/api/job")

        expect(job).to have_been_requested
        expect(client).to be_legacy_api
      end

      it "doesn't remember a failed detection" do
        stub_request(:get, "#{base}/api/version").to_raise(Errno::ECONNREFUSED)
                                                 .then.to_return(version_body.call("1.11.8"))
        client = new_client(:auto)

        expect { client.api_version }.to raise_error(Octoprint::Exceptions::ConnectionError)
        expect(client.server_version).to be_nil
        expect(client.api_version).to eq Octoprint::ApiVersion::V1_11
      end

      it "raises the mapped error when the server refuses the detection" do
        stub_request(:get, "#{base}/api/version").to_return(status: 403, body: { error: "Forbidden" }.to_json)

        expect { new_client(:auto).api_version }
          .to raise_error(Octoprint::Exceptions::AuthenticationError, "[403] Forbidden")
      end

      it "detects once when threads share the client" do
        detection = stub_request(:get, "#{base}/api/version").to_return do
          sleep 0.05
          version_body.call("2.0.0rc7")
        end
        client = new_client(:auto)

        Array.new(5) { Thread.new { client.api_version } }.each(&:join)

        expect(detection).to have_been_requested.once
      end

      it "detects again after refresh_version!" do
        detection = stub_request(:get, "#{base}/api/version").to_return(version_body.call("1.11.8"))
                                                             .then.to_return(version_body.call("2.0.0"))
        client = new_client(:auto)

        expect(client.api_version).to eq Octoprint::ApiVersion::V1_11
        expect(client.refresh_version!).to be_nil
        expect(client.server_version).to be_nil
        expect(client.api_version).to eq Octoprint::ApiVersion::V2_0
        expect(detection).to have_been_requested.twice
      end
    end

    describe "#supports?" do
      it "is false for 2.0 features with the 1.11 API" do
        expect(new_client.supports?(:connectors)).to be false
      end

      it "is true for 2.0 features with the 2.0 API" do
        expect(new_client("2.0").supports?(:connectors)).to be true
      end

      it "raises for an unknown feature" do
        expect { new_client.supports?(:teleport) }.to raise_error(ArgumentError, /Unknown feature/)
      end
    end

    describe "#require_feature!" do
      it "passes when the API version has the feature" do
        expect { new_client("2.0").require_feature!(:refresh_thumbnails) }.not_to raise_error
      end

      it "raises UnsupportedFeatureError without reaching the server" do
        expect { new_client.require_feature!(:refresh_thumbnails) }
          .to raise_error(Octoprint::Exceptions::UnsupportedFeatureError,
                          "refresh_thumbnails needs the OctoPrint 2.0 API, but this client uses the 1.11 API")
      end

      it "names the detected server version" do
        stub_request(:get, "#{base}/api/version").to_return(version_body.call("1.11.8"))

        expect { new_client(:auto).require_feature!(:connectors) }
          .to raise_error(Octoprint::Exceptions::UnsupportedFeatureError, /uses the 1.11 API \(OctoPrint 1.11.8\)/)
      end
    end
  end
end
