# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Util do
  include_context "with default Octoprint config"

  describe "#initialize" do
    it "creates Util object with result, exists, and status" do
      util = described_class.new(result: "success", exists: true, status: "ok")

      expect(util.result).to eq("success")
      expect(util.exists).to be(true)
      expect(util.status).to eq("ok")
    end

    it "handles optional parameters" do
      util = described_class.new(result: "test")

      expect(util.result).to eq("test")
      expect(util.exists).to be_nil
      expect(util.status).to be_nil
    end
  end

  describe "inheritance and configuration" do
    it "inherits from BaseResource" do
      expect(described_class).to be < Octoprint::BaseResource
    end

    it "has correct resource path" do
      expect(described_class.instance_variable_get(:@path)).to eq("/api/util")
    end
  end

  describe "method signatures and behavior patterns" do
    let(:client) { Octoprint::Client.new(host: "http://test.local", api_key: "test_key") }

    before do
      allow(described_class).to receive_messages(
        client: client,
        deserialize: described_class.new(result: "success")
      )
      allow(client).to receive(:request).and_return({ result: "success" })
    end

    describe ".test_path" do
      it "constructs correct POST request with mandatory path parameter" do
        allow(described_class).to receive(:post).and_return({ result: "exists" })

        described_class.test_path(path: "/tmp/test")

        expect(described_class).to have_received(:post).with(
          path: "/api/util/test",
          params: { command: "path", path: "/tmp/test" }
        )
      end

      it "includes optional parameters when provided" do
        allow(described_class).to receive(:post).and_return({ result: "exists" })

        described_class.test_path(
          path: "/tmp/test",
          check_type: "file",
          check_access: "rw",
          allow_create_dir: true,
          check_writable_dir: false
        )

        expect(described_class).to have_received(:post).with(
          path: "/api/util/test",
          params: {
            command: "path",
            path: "/tmp/test",
            check_type: "file",
            check_access: "rw",
            allow_create_dir: true,
            check_writable_dir: false
          }
        )
      end

      it "excludes nil optional parameters" do
        allow(described_class).to receive(:post).and_return({ result: "exists" })

        described_class.test_path(path: "/tmp/test", check_type: nil)

        expect(described_class).to have_received(:post).with(
          path: "/api/util/test",
          params: { command: "path", path: "/tmp/test" }
        )
      end
    end

    describe ".test_url" do
      it "constructs correct POST request with mandatory url parameter" do
        allow(described_class).to receive(:post).and_return({ result: "reachable" })

        described_class.test_url(url: "https://example.com")

        expect(described_class).to have_received(:post).with(
          path: "/api/util/test",
          params: { command: "url", url: "https://example.com" }
        )
      end

      it "includes all optional parameters when provided" do
        allow(described_class).to receive(:post).and_return({ result: "reachable" })

        described_class.test_url(
          url: "https://example.com",
          method: "GET",
          timeout: 5,
          status: 200,
          auth_user: "user",
          auth_pass: "pass",
          auth_digest: "digest",
          auth_bearer: "token",
          content_type_whitelist: "application/json",
          content_type_blacklist: "text/html"
        )

        expect(described_class).to have_received(:post).with(
          path: "/api/util/test",
          params: {
            command: "url",
            url: "https://example.com",
            method: "GET",
            timeout: 5,
            status: 200,
            auth_user: "user",
            auth_pass: "pass",
            auth_digest: "digest",
            auth_bearer: "token",
            content_type_whitelist: "application/json",
            content_type_blacklist: "text/html"
          }
        )
      end
    end

    describe ".test_server" do
      it "constructs correct POST request with mandatory host and port" do
        allow(described_class).to receive(:post).and_return({ result: "reachable" })

        described_class.test_server(host: "example.com", port: 80)

        expect(described_class).to have_received(:post).with(
          path: "/api/util/test",
          params: { command: "server", host: "example.com", port: 80 }
        )
      end

      it "includes optional protocol and timeout parameters" do
        allow(described_class).to receive(:post).and_return({ result: "reachable" })

        described_class.test_server(
          host: "example.com",
          port: 443,
          protocol: "TCP",
          timeout: 5.0
        )

        expect(described_class).to have_received(:post).with(
          path: "/api/util/test",
          params: {
            command: "server",
            host: "example.com",
            port: 443,
            protocol: "TCP",
            timeout: 5.0
          }
        )
      end
    end

    describe ".test_resolution" do
      it "constructs correct POST request with mandatory name parameter" do
        allow(described_class).to receive(:post).and_return({ result: "resolved" })

        described_class.test_resolution(name: "example.com")

        expect(described_class).to have_received(:post).with(
          path: "/api/util/test",
          params: { command: "resolution", name: "example.com" }
        )
      end
    end

    describe ".test_address" do
      it "constructs correct POST request with no parameters" do
        allow(described_class).to receive(:post).and_return({ result: "address" })

        described_class.test_address

        expect(described_class).to have_received(:post).with(
          path: "/api/util/test",
          params: { command: "address" }
        )
      end

      it "includes address parameter when provided" do
        allow(described_class).to receive(:post).and_return({ result: "address" })

        described_class.test_address(address: "192.168.1.1")

        expect(described_class).to have_received(:post).with(
          path: "/api/util/test",
          params: { command: "address", address: "192.168.1.1" }
        )
      end
    end
  end

  describe "response handling" do
    let(:client) { Octoprint::Client.new(host: "http://test.local", api_key: "test_key") }

    before do
      allow(described_class).to receive(:client).and_return(client)
    end

    it "deserializes response data correctly" do
      response_data = { result: "exists", exists: true, status: "ok" }
      allow(described_class).to receive(:post).and_return(response_data)

      result = described_class.test_path(path: "/tmp/test")

      expect(result).to be_a(described_class)
      expect(result.result).to eq("exists")
      expect(result.exists).to be(true)
      expect(result.status).to eq("ok")
    end
  end

  describe "edge cases in method parameters" do
    before do
      allow(described_class).to receive_messages(
        post: { result: "success" },
        deserialize: described_class.new(result: "success")
      )
    end

    it "handles boolean false values correctly in test_path" do
      described_class.test_path(
        path: "/tmp/test",
        allow_create_dir: false,
        check_writable_dir: false
      )

      expect(described_class).to have_received(:post).with(
        path: "/api/util/test",
        params: {
          command: "path",
          path: "/tmp/test",
          allow_create_dir: false,
          check_writable_dir: false
        }
      )
    end

    it "handles timeout as integer in test_url" do
      described_class.test_url(url: "https://example.com", timeout: 10)

      expect(described_class).to have_received(:post).with(
        path: "/api/util/test",
        params: { command: "url", url: "https://example.com", timeout: 10 }
      )
    end

    it "handles timeout as float in test_server" do
      described_class.test_server(host: "example.com", port: 80, timeout: 3.5)

      expect(described_class).to have_received(:post).with(
        path: "/api/util/test",
        params: { command: "server", host: "example.com", port: 80, timeout: 3.5 }
      )
    end
  end
end
