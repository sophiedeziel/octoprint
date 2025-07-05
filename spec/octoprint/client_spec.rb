# typed: true
# frozen_string_literal: true

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
    end
  end
end
