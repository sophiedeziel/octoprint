# typed: true
# frozen_string_literal: true

# The cassettes match on the request body, so replaying them checks the parameter names sent to each API version
RSpec.shared_examples "URL tests with content type filters" do |prefix|
  let(:url) { "https://httpbin.org/json" } # answers with application/json

  {
    "allowlist" => { allowed: ["application/*"], refused: ["text/html"] },
    "blocklist" => { allowed: ["text/html"], refused: ["application/json"] }
  }.each do |filter, types|
    describe "with a content type #{filter}" do
      subject(:test_result) { described_class.test_url(url: url, "content_type_#{filter}": content_types) }

      context "when the content type is refused",
              vcr: { cassette_name: "#{prefix}/test_url_#{filter}_refused", match_requests_on: %i[method uri body] } do
        let(:content_types) { types[:refused] }

        its(:result) { is_expected.to be false }
      end

      context "when the content type is allowed",
              vcr: { cassette_name: "#{prefix}/test_url_#{filter}_allowed", match_requests_on: %i[method uri body] } do
        let(:content_types) { types[:allowed] }

        its(:result) { is_expected.to be true }
      end
    end
  end
end

RSpec.describe Octoprint::Util, type: :integration do
  include_context "with default Octoprint config"

  describe "Test file system path", vcr: { cassette_name: "util/test_path" } do
    use_octoprint_server

    subject(:test_result) { described_class.test_path(path: "/tmp") }

    it { is_expected.to be_a described_class }
    its(:result) { is_expected.not_to be_nil }
    its(:exists) { is_expected.not_to be_nil }

    context "when testing an existing path" do
      subject(:test_result) { described_class.test_path(path: "/tmp") }

      it "returns successful result" do
        expect(test_result.exists).to be(true)
      end
    end

    context "when testing with check_type parameter", vcr: { cassette_name: "util/test_path_with_type" } do
      subject(:test_result) { described_class.test_path(path: "/tmp", check_type: "directory") }

      it { is_expected.to be_a described_class }
    end

    context "when testing with all optional parameters", vcr: { cassette_name: "util/test_path_full" } do
      subject(:test_result) do
        described_class.test_path(
          path: "/tmp",
          check_type: "directory",
          check_access: "rw",
          allow_create_dir: true,
          check_writable_dir: true
        )
      end

      it { is_expected.to be_a described_class }
    end
  end

  describe "Test URL connectivity", vcr: { cassette_name: "util/test_url" } do
    use_octoprint_server

    subject(:test_result) { described_class.test_url(url: "https://httpbin.org/status/200") }

    it { is_expected.to be_a described_class }
    its(:result) { is_expected.not_to be_nil }
    its(:status) { is_expected.not_to be_nil }

    context "when testing with method parameter", vcr: { cassette_name: "util/test_url_with_method" } do
      subject(:test_result) { described_class.test_url(url: "https://httpbin.org/get", method: "GET") }

      it { is_expected.to be_a described_class }
    end

    context "when testing with timeout", vcr: { cassette_name: "util/test_url_with_timeout" } do
      subject(:test_result) { described_class.test_url(url: "https://httpbin.org/delay/1", timeout: 5) }

      it { is_expected.to be_a described_class }
    end

    context "when testing with expected status", vcr: { cassette_name: "util/test_url_with_status" } do
      subject(:test_result) { described_class.test_url(url: "https://httpbin.org/status/404", status: 404) }

      it { is_expected.to be_a described_class }
    end

    context "when testing with authentication", vcr: { cassette_name: "util/test_url_with_auth" } do
      subject(:test_result) do
        described_class.test_url(
          url: "https://httpbin.org/basic-auth/user/pass",
          auth_user: "user",
          auth_pass: "pass"
        )
      end

      it { is_expected.to be_a described_class }
    end
  end

  on_octoprint_versions do
    use_octoprint_server

    it_behaves_like "URL tests with content type filters", "util"
  end

  context "with the 1.11 API against OctoPrint 2.0", api_version: "1.11", octoprint: "2.0" do
    use_octoprint_server

    it_behaves_like "URL tests with content type filters", "util/api_1_11"
  end

  describe "Test server connectivity", vcr: { cassette_name: "util/test_server" } do
    use_octoprint_server

    subject(:test_result) { described_class.test_server(host: "google.com", port: 80) }

    it { is_expected.to be_a described_class }
    its(:result) { is_expected.not_to be_nil }

    context "when testing HTTPS port", vcr: { cassette_name: "util/test_server_https" } do
      subject(:test_result) { described_class.test_server(host: "google.com", port: 443) }

      it { is_expected.to be_a described_class }
    end

    context "when testing with timeout", vcr: { cassette_name: "util/test_server_with_timeout" } do
      subject(:test_result) do
        described_class.test_server(
          host: "google.com",
          port: 80,
          timeout: 5.0
        )
      end

      it { is_expected.to be_a described_class }
      its(:result) { is_expected.not_to be_nil }
    end

    context "when testing unreachable server", vcr: { cassette_name: "util/test_server_unreachable" } do
      subject(:test_result) { described_class.test_server(host: "192.0.2.1", port: 9999) }

      it { is_expected.to be_a described_class }
    end
  end

  describe "Test DNS resolution", vcr: { cassette_name: "util/test_resolution" } do
    use_octoprint_server

    subject(:test_result) { described_class.test_resolution(name: "google.com") }

    it { is_expected.to be_a described_class }
    its(:result) { is_expected.not_to be_nil }

    context "when testing non-existent domain", vcr: { cassette_name: "util/test_resolution_fail" } do
      subject(:test_result) { described_class.test_resolution(name: "nonexistent-domain-12345.com") }

      it { is_expected.to be_a described_class }
    end
  end

  describe "Test network address", vcr: { cassette_name: "util/test_address" } do
    use_octoprint_server

    subject(:test_result) { described_class.test_address }

    it { is_expected.to be_a described_class }

    it "returns a result (may be nil for address test)" do
      expect(test_result.result).to be_a(String).or be_nil
    end

    context "when testing specific address", vcr: { cassette_name: "util/test_address_specific" } do
      subject(:test_result) { described_class.test_address(address: "127.0.0.1") }

      it { is_expected.to be_a described_class }
    end
  end

  describe "Error handling" do
    use_octoprint_server

    context "when testing with invalid parameters", vcr: { cassette_name: "util/test_invalid" } do
      it "handles API errors gracefully" do
        expect do
          described_class.test_path(path: "")
        end.not_to raise_error
      end
    end
  end
end
