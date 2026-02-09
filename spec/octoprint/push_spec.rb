# typed: false
# frozen_string_literal: true

RSpec.describe Octoprint::Push do
  include_context "with default Octoprint config"

  describe "inheritance and configuration" do
    it "inherits from BaseResource" do
      expect(described_class).to be < Octoprint::BaseResource
    end

    it "has correct resource path" do
      expect(described_class.instance_variable_get(:@path)).to eq("/sockjs")
    end
  end

  describe "instance" do
    subject(:push) { described_class.new(session_id: "test_session") }

    its(:session_id) { is_expected.to eq "test_session" }
    its(:server_id)  { is_expected.to eq "000" }
  end

  describe "SockJS operations" do
    let(:client) { Octoprint::Client.new(host: "http://test.local", api_key: "test_key") }
    let(:faraday) { client.client }

    before do
      Octoprint.configure(host: "http://test.local", api_key: "test_key")
      allow(Octoprint).to receive(:client).and_return(client)
    end

    describe ".subscribe" do
      let(:open_response) { instance_double(Faraday::Response, body: "o\n") }
      let(:send_response) { instance_double(Faraday::Response, body: "", status: 204) }
      let(:connected_response) do
        body = 'a["{\"connected\":{\"version\":\"1.11.6\",\"display_version\":\"1.11.6\"}}"]'
        instance_double(Faraday::Response, body: body)
      end

      before do
        call_count = 0
        allow(faraday).to receive(:post) do |path, *_args|
          if path.end_with?("xhr_send")
            send_response
          elsif path.end_with?("xhr")
            call_count += 1
            call_count == 1 ? open_response : connected_response
          end
        end
      end

      it "returns a Push instance" do
        result = described_class.subscribe(session_id: "test_session")
        expect(result).to be_a described_class
      end

      it "opens a SockJS session" do
        described_class.subscribe(session_id: "test_session")
        expect(faraday).to have_received(:post).with("/sockjs/000/test_session/xhr").at_least(:once)
      end

      it "authenticates with the API key" do
        described_class.subscribe(session_id: "test_session")
        expect(faraday).to have_received(:post).with(
          "/sockjs/000/test_session/xhr_send",
          ['{"auth":"_api:test_key"}'].to_json,
          { "Content-Type" => "application/json" }
        )
      end

      it "sends a subscribe command" do
        described_class.subscribe(session_id: "test_session")
        expect(faraday).to have_received(:post).with(
          "/sockjs/000/test_session/xhr_send",
          ['{"subscribe":{"state":true,"events":true,"plugins":true}}'].to_json,
          { "Content-Type" => "application/json" }
        )
      end

      it "passes custom filters to subscribe" do
        described_class.subscribe(
          state: false,
          events: ["PrintDone"],
          plugins: false,
          session_id: "test_session"
        )
        expect(faraday).to have_received(:post).with(
          "/sockjs/000/test_session/xhr_send",
          ['{"subscribe":{"state":false,"events":["PrintDone"],"plugins":false}}'].to_json,
          { "Content-Type" => "application/json" }
        )
      end
    end

    describe "#unsubscribe" do
      subject(:push) { described_class.new(session_id: "test_session") }

      let(:send_response) { instance_double(Faraday::Response, body: "", status: 204) }

      before do
        allow(faraday).to receive(:post).and_return(send_response)
      end

      it "sends an unsubscribe command" do
        push.unsubscribe
        expect(faraday).to have_received(:post).with(
          "/sockjs/000/test_session/xhr_send",
          ['{"subscribe":{"state":false,"events":false,"plugins":false}}'].to_json,
          { "Content-Type" => "application/json" }
        )
      end

      it "returns true" do
        expect(push.unsubscribe).to be true
      end
    end

    describe ".test" do
      let(:open_response) { instance_double(Faraday::Response, body: "o\n") }
      let(:send_response) { instance_double(Faraday::Response, body: "", status: 204) }
      let(:connected_response) do
        body = 'a["{\"connected\":{\"version\":\"1.11.6\",\"display_version\":\"1.11.6\",\"branch\":\"main\"}}"]'
        instance_double(Faraday::Response, body: body)
      end

      before do
        call_count = 0
        allow(faraday).to receive(:post) do |path, *_args|
          if path.end_with?("xhr_send")
            send_response
          elsif path.end_with?("xhr")
            call_count += 1
            call_count == 1 ? open_response : connected_response
          end
        end
      end

      it "returns the connected message data" do
        result = described_class.test(session_id: "test_session")
        expect(result).to include(:version)
        expect(result[:version]).to eq("1.11.6")
      end

      it "returns display version" do
        result = described_class.test(session_id: "test_session")
        expect(result[:display_version]).to eq("1.11.6")
      end

      it "returns branch" do
        result = described_class.test(session_id: "test_session")
        expect(result[:branch]).to eq("main")
      end

      it "returns empty hash when no connected message" do
        no_connected = 'a["{\"reauthRequired\":{\"reason\":\"stale\"}}"]'
        call_count = 0
        allow(faraday).to receive(:post) do |path, *_args|
          if path.end_with?("xhr_send")
            send_response
          elsif path.end_with?("xhr")
            call_count += 1
            body = call_count == 1 ? "o\n" : no_connected
            instance_double(Faraday::Response, body: body)
          end
        end

        result = described_class.test(session_id: "test_session")
        expect(result).to eq({})
      end
    end

    describe "#receive" do
      subject(:push) { described_class.new(session_id: "test_session") }

      it "parses SockJS array messages" do
        message = 'a["{\"current\":{\"state\":\"Operational\"}}"]'
        allow(faraday).to receive(:post).and_return(
          instance_double(Faraday::Response, body: message)
        )

        result = push.receive
        expect(result).to eq([{ current: { state: "Operational" } }])
      end

      it "returns empty array for heartbeat frames" do
        allow(faraday).to receive(:post).and_return(
          instance_double(Faraday::Response, body: "h")
        )

        expect(push.receive).to eq([])
      end

      it "returns empty array for empty body" do
        allow(faraday).to receive(:post).and_return(
          instance_double(Faraday::Response, body: "")
        )

        expect(push.receive).to eq([])
      end

      it "transforms camelCase keys to snake_case symbols" do
        message = 'a["{\"connected\":{\"displayVersion\":\"1.11.6\",\"pluginHash\":\"abc\"}}"]'
        allow(faraday).to receive(:post).and_return(
          instance_double(Faraday::Response, body: message)
        )

        result = push.receive
        expect(result.first[:connected]).to include(:display_version, :plugin_hash)
      end
    end

    describe "#open_session" do
      subject(:push) { described_class.new(session_id: "test_session") }

      it "returns true when session opens successfully" do
        allow(faraday).to receive(:post).and_return(
          instance_double(Faraday::Response, body: "o\n")
        )

        expect(push.open_session).to be true
      end

      it "returns false when session fails to open" do
        allow(faraday).to receive(:post).and_return(
          instance_double(Faraday::Response, body: "c[3000,\"Go away!\"]")
        )

        expect(push.open_session).to be false
      end
    end

    describe "#authenticate" do
      subject(:push) { described_class.new(session_id: "test_session") }

      let(:send_response) { instance_double(Faraday::Response, body: "", status: 204) }

      before do
        allow(faraday).to receive(:post).and_return(send_response)
      end

      it "sends auth command with API key" do
        push.authenticate
        expect(faraday).to have_received(:post).with(
          "/sockjs/000/test_session/xhr_send",
          ['{"auth":"_api:test_key"}'].to_json,
          { "Content-Type" => "application/json" }
        )
      end
    end

    describe "#send_subscribe" do
      subject(:push) { described_class.new(session_id: "test_session") }

      let(:send_response) { instance_double(Faraday::Response, body: "", status: 204) }

      before do
        allow(faraday).to receive(:post).and_return(send_response)
      end

      it "sends subscribe command with filters" do
        push.send_subscribe(state: true, events: ["PrintDone"], plugins: false)
        expect(faraday).to have_received(:post).with(
          "/sockjs/000/test_session/xhr_send",
          ['{"subscribe":{"state":true,"events":["PrintDone"],"plugins":false}}'].to_json,
          { "Content-Type" => "application/json" }
        )
      end
    end
  end
end
