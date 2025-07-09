# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::BaseResource do
  include_context "with default Octoprint config"

  let(:test_class) do
    Class.new(described_class) do
      resource_path "/api/test"
    end
  end

  let(:client) { Octoprint::Client.new(host: "http://test.local", api_key: "test_key") }

  before do
    # Stub the private client method to return a real client instance
    allow(test_class).to receive(:client).and_return(client)
  end

  describe ".resource_path" do
    it "sets the path for the resource" do
      test_class.resource_path("/api/custom")
      expect(test_class.instance_variable_get(:@path)).to eq("/api/custom")
    end
  end

  describe ".fetch_resource" do
    let(:mock_response) { { "name" => "test", "value" => 123 } }

    before do
      allow(client).to receive(:request).and_return(mock_response)
    end

    context "with default parameters" do
      it "makes a GET request to the resource path" do
        test_class.fetch_resource
        expect(client).to have_received(:request).with("/api/test", http_method: :get)
      end

      it "deserializes the response by default" do
        allow(test_class).to receive(:deserialize).with(mock_response).and_return("deserialized")
        result = test_class.fetch_resource
        expect(result).to eq("deserialized")
      end
    end

    context "with custom path" do
      it "appends the path to the resource path" do
        test_class.fetch_resource("custom")
        expect(client).to have_received(:request).with("/api/test/custom", http_method: :get)
      end
    end

    context "with options" do
      it "builds query string from options" do
        test_class.fetch_resource(options: { param1: "value1", param2: "value2" })
        expect(client).to have_received(:request).with("/api/test?param1=value1&param2=value2", http_method: :get)
      end
    end

    context "with deserialize: false" do
      it "returns raw response without deserialization" do
        allow(test_class).to receive(:deserialize)
        result = test_class.fetch_resource(deserialize: false)
        expect(result).to eq(mock_response)
        expect(test_class).not_to have_received(:deserialize)
      end
    end
  end

  describe ".post" do
    let(:params) { { command: "test" } }
    let(:headers) { { "Content-Type" => "application/json" } }
    let(:options) { { timeout: 30 } }

    before do
      allow(client).to receive(:request).and_return(true)
    end

    context "with default parameters" do
      it "makes a POST request to the resource path" do
        test_class.post
        expect(client).to have_received(:request).with(
          "/api/test",
          http_method: :post,
          body: {},
          headers: {},
          options: {}
        )
      end
    end

    context "with custom parameters" do
      it "makes a POST request with provided parameters" do
        test_class.post(path: "/custom", params: params, headers: headers, options: options)
        expect(client).to have_received(:request).with(
          "/custom",
          http_method: :post,
          body: params,
          headers: headers,
          options: options
        )
      end
    end
  end

  describe ".put" do
    let(:params) { { name: "updated" } }
    let(:headers) { { "Content-Type" => "application/json" } }
    let(:options) { { timeout: 30 } }

    before do
      allow(client).to receive(:request).and_return(true)
    end

    context "with default parameters" do
      it "makes a PUT request to the resource path" do
        test_class.put
        expect(client).to have_received(:request).with(
          "/api/test",
          http_method: :put,
          body: {},
          headers: {},
          options: {}
        )
      end
    end

    context "with custom parameters" do
      it "makes a PUT request with provided parameters" do
        test_class.put(path: "/custom", params: params, headers: headers, options: options)
        expect(client).to have_received(:request).with(
          "/custom",
          http_method: :put,
          body: params,
          headers: headers,
          options: options
        )
      end
    end
  end

  describe ".patch" do
    let(:params) { { status: "active" } }
    let(:headers) { { "Authorization" => "Bearer token" } }
    let(:options) { { timeout: 45 } }

    before do
      allow(client).to receive(:request).and_return(true)
    end

    context "with default parameters" do
      it "makes a PATCH request to the resource path" do
        test_class.patch
        expect(client).to have_received(:request).with(
          "/api/test",
          http_method: :patch,
          body: {},
          headers: {},
          options: {}
        )
      end
    end

    context "with custom parameters" do
      it "makes a PATCH request with provided parameters" do
        test_class.patch(path: "/custom", params: params, headers: headers, options: options)
        expect(client).to have_received(:request).with(
          "/custom",
          http_method: :patch,
          body: params,
          headers: headers,
          options: options
        )
      end
    end
  end

  describe ".delete" do
    let(:params) { { force: true } }
    let(:headers) { { "Authorization" => "Bearer token" } }
    let(:options) { { timeout: 60 } }

    before do
      allow(client).to receive(:request).and_return(true)
    end

    context "with default parameters" do
      it "makes a DELETE request to the resource path" do
        test_class.delete
        expect(client).to have_received(:request).with(
          "/api/test",
          http_method: :delete,
          body: nil,
          headers: {},
          options: {}
        )
      end
    end

    context "with empty params" do
      it "sends nil body when params are empty" do
        test_class.delete(params: {})
        expect(client).to have_received(:request).with(
          "/api/test",
          http_method: :delete,
          body: nil,
          headers: {},
          options: {}
        )
      end
    end

    context "with non-empty params" do
      it "sends params as body when params are not empty" do
        test_class.delete(params: params)
        expect(client).to have_received(:request).with(
          "/api/test",
          http_method: :delete,
          body: params,
          headers: {},
          options: {}
        )
      end
    end

    context "with custom parameters" do
      it "makes a DELETE request with provided parameters" do
        test_class.delete(path: "/custom", params: params, headers: headers, options: options)
        expect(client).to have_received(:request).with(
          "/custom",
          http_method: :delete,
          body: params,
          headers: headers,
          options: options
        )
      end
    end
  end

  describe ".deserialize" do
    let(:attrs) { { name: "test", value: 123 } }

    it "creates a new instance with the provided attributes" do
      allow(test_class).to receive(:new).with(**attrs).and_return("instance")
      result = test_class.deserialize(attrs)
      expect(result).to eq("instance")
    end
  end

  describe ".client" do
    context "when client is configured" do
      it "returns the configured client" do
        result = test_class.send(:client)
        expect(result).to eq(client)
      end
    end

    context "when no client is configured" do
      it "raises an error" do
        # Remove the stub so the original method gets called
        allow(test_class).to receive(:client).and_call_original
        allow(Octoprint).to receive(:client).and_return(nil)
        expect { test_class.send(:client) }.to raise_error("No client configured")
      end
    end
  end

  describe "edge case coverage" do
    it "handles fetch_resource with empty options" do
      allow(client).to receive(:request).and_return({})

      # Test query string building with empty hash
      test_class.fetch_resource(options: {})

      expect(client).to have_received(:request).with("/api/test", http_method: :get)
    end
  end

  describe "#initialize" do
    it "accepts arbitrary keyword arguments" do
      expect { test_class.new(name: "test", value: 123) }.not_to raise_error
    end
  end
end
