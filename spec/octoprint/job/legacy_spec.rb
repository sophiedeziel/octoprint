# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Job::Legacy do
  let(:get_request) { Octoprint::ApiRequest.new(http_method: :get, path: "/api/job") }

  it "is the converter of the Job resource" do
    expect(Octoprint::Job.legacy_converter).to eq described_class
  end

  describe ".to_request" do
    it "keeps the request" do
      expect(described_class.to_request(get_request)).to eq get_request
    end
  end

  describe ".from_response" do
    subject(:converted) { described_class.from_response(response, get_request) }

    # spec/cassettes/job/get_idle.yml (1.11.8), keys as parsed by the client
    context "with an idle 1.11.8 job" do
      let(:response) do
        {
          job: {
            estimated_print_time: nil, filament: { length: nil, volume: nil },
            file: { date: nil, name: nil, origin: nil, path: nil, size: nil },
            last_print_time: nil, user: nil
          },
          progress: { completion: nil, filepos: nil, print_time: nil, print_time_left: nil,
                      print_time_left_origin: nil },
          state: "Operational"
        }
      end

      it "leaves out the null fields, like 2.0 does" do
        expect(converted).to eq(job: { file: {} }, progress: {}, state: "Operational")
      end
    end

    # spec/cassettes/job/get_printing.yml (1.11.8)
    context "with a 1.11.8 job that is printing" do
      let(:response) do
        {
          job: {
            average_print_time: 31.265309458001866, estimated_print_time: 34.949892090338835,
            filament: { tool0: { length: 60.0, volume: 0.0 } },
            file: { date: 1_794_809_291, display: "job_test.gcode", name: "job_test.gcode", origin: "local",
                    path: "job_test.gcode", size: 2073 },
            last_print_time: 31.265309458001866, user: "admin"
          },
          progress: { completion: 16.160154365653643, filepos: 335, print_time: 4, print_time_left: 26,
                      print_time_left_origin: "average" },
          state: "Printing"
        }
      end

      it "keeps every field that has a value" do
        expect(converted).to eq response
      end
    end

    # spec/cassettes/2_0/job/get_idle_api_1_11.yml (2.0.0rc7 without the version header)
    context "with an idle job from a 2.0 server" do
      let(:response) do
        {
          error: nil,
          job: {
            estimated_print_time: nil, filament: nil,
            file: { date: nil, display: nil, name: nil, origin: nil, path: nil, size: nil, upload: nil },
            last_print_time: nil, user: nil
          },
          progress: { completion: nil, filepos: nil, print_time: nil, print_time_left: nil,
                      print_time_left_origin: nil },
          state: "Operational"
        }
      end

      it "gives the 2.0 API response" do
        # spec/cassettes/2_0/job/get_idle.yml
        expect(converted).to eq(job: { file: {} }, progress: {}, state: "Operational")
      end
    end

    # spec/cassettes/2_0/job/get_printing_api_1_11.yml
    context "with a printing job from a 2.0 server" do
      let(:response) do
        {
          error: nil,
          job: {
            estimated_print_time: 34.949892090338835,
            filament: { tool0: { length: 60.0, volume: 0.0, weight: nil } },
            file: { date: 1_794_809_291, display: "job_test.gcode", name: "job_test.gcode", origin: "local",
                    path: "job_test.gcode", size: 2073, upload: false },
            last_print_time: nil, user: "admin"
          },
          progress: { completion: 16.160154365653643, filepos: 335, print_time: 4, print_time_left: 30,
                      print_time_left_origin: "analysis" },
          state: "Printing"
        }
      end

      it "gives the 2.0 API response, keeping upload: false and the nested filament fields" do
        # spec/cassettes/2_0/job/get_printing.yml
        expect(converted).to eq(
          job: {
            estimated_print_time: 34.949892090338835,
            filament: { tool0: { length: 60.0, volume: 0.0, weight: nil } },
            file: { date: 1_794_809_291, display: "job_test.gcode", name: "job_test.gcode", origin: "local",
                    path: "job_test.gcode", size: 2073, upload: false },
            user: "admin"
          },
          progress: { completion: 16.160154365653643, filepos: 335, print_time: 4, print_time_left: 30,
                      print_time_left_origin: "analysis" },
          state: "Printing"
        )
      end
    end

    context "with an error" do
      let(:response) { { error: "Printer disconnected", state: "Error" } }

      it "keeps it" do
        expect(converted).to eq response
      end
    end

    context "with a file without a display name" do
      let(:response) { { job: { file: { name: "part.gcode", origin: "local", path: "folder/part.gcode" } } } }

      it "uses the file name" do
        expect(converted.dig(:job, :file)).to eq(display: "part.gcode", name: "part.gcode", origin: "local",
                                                 path: "folder/part.gcode")
      end
    end

    it "doesn't modify the response it gets" do
      response = { job: { file: { name: nil }, user: nil }, progress: { completion: nil } }

      described_class.from_response(response, get_request)

      expect(response).to eq(job: { file: { name: nil }, user: nil }, progress: { completion: nil })
    end

    it "returns the response of a command unchanged" do
      request = Octoprint::ApiRequest.new(http_method: :post, path: "/api/job", body: { command: "start" })

      expect(described_class.from_response(true, request)).to be true
    end
  end

  describe "with Job.get" do
    include WebMock::API

    after { WebMock.reset! }

    let(:host) { "http://octoprint.test" }
    let(:body) { { job: { file: { name: nil }, last_print_time: nil }, progress: {}, state: "Offline" } }

    before { stub_request(:get, "#{host}/api/job").to_return(body: body.to_json) }

    it "converts the response with the 1.x API" do
      Octoprint.configure(host: host, api_key: "key", api_version: "1.11")

      job = Octoprint::Job.get

      expect(job.information.file.to_h).to eq({})
      expect(job.extra).to be_nil
    end

    it "doesn't convert the response with the 2.0 API" do
      Octoprint.configure(host: host, api_key: "key", api_version: "2.0")
      allow(described_class).to receive(:from_response).and_call_original

      expect(Octoprint::Job.get.information.file.name).to be_nil
      expect(described_class).not_to have_received(:from_response)
    end
  end
end
