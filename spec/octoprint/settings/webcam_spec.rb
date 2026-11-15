# typed: false
# frozen_string_literal: true

RSpec.describe Octoprint::Settings::Webcam do
  describe ".from_settings" do
    subject(:webcam) { described_class.from_settings(settings) }

    context "with the multi-webcam settings of OctoPrint 1.9+" do
      let(:settings) do
        {
          webcam: {
            webcam_enabled: true,
            default_webcam: "garage",
            stream_url: "/webcam/?action=stream",
            snapshot_url: "http://localhost:8080/?action=snapshot",
            flip_h: false,
            stream_ratio: "16:9",
            webcams: [
              {
                name: "classic",
                display_name: "Classic Webcam",
                compat: { stream: "/webcam/?action=stream", snapshot: "http://localhost:8080/?action=snapshot" }
              },
              {
                name: "garage",
                display_name: "Garage Cam",
                flip_h: true,
                flip_v: false,
                rotate90: true,
                snapshot_display: "http://garage.local/snapshot.jpg",
                compat: { stream: "http://garage.local/stream", stream_ratio: "4:3" }
              }
            ]
          }
        }
      end

      it { is_expected.to be_a described_class }

      it "uses the default webcam" do
        expect(webcam).to have_attributes(
          enabled: true,
          name: "garage",
          display_name: "Garage Cam",
          stream_url: "http://garage.local/stream",
          stream_ratio: "4:3",
          flip_h: true,
          flip_v: false,
          rotate90: true
        )
      end

      it "falls back to the snapshot display URL" do
        expect(webcam.snapshot_url).to eq "http://garage.local/snapshot.jpg"
      end
    end

    context "when the default webcam isn't in the list" do
      let(:settings) do
        {
          webcam: {
            webcam_enabled: true,
            default_webcam: "missing",
            webcams: [{ name: "first", extras: { stream: "/first/stream", stream_ratio: "16:9" } }]
          }
        }
      end

      it "uses the first webcam" do
        expect(webcam).to have_attributes(name: "first", stream_url: "/first/stream", stream_ratio: "16:9")
      end
    end

    context "when the default webcam is a plugin webcam without compat settings" do
      let(:settings) do
        {
          webcam: {
            webcam_enabled: true,
            default_webcam: "webrtc",
            stream_url: "/webcam/?action=stream",
            snapshot_url: "http://localhost:8080/?action=snapshot",
            stream_ratio: "16:9",
            webcams: [
              { name: "classic", compat: { stream: "/webcam/?action=stream" } },
              { name: "webrtc", display_name: "WebRTC Cam", snapshot_display: "Snapshots via go2rtc", extras: {} }
            ]
          }
        }
      end

      it "doesn't mix in the legacy keys of another webcam" do
        expect(webcam).to have_attributes(
          enabled: true,
          name: "webrtc",
          display_name: "WebRTC Cam",
          stream_url: nil,
          stream_ratio: nil
        )
      end

      it "ignores a snapshot display that isn't a URL" do
        expect(webcam.snapshot_url).to be_nil
      end
    end

    context "with an empty webcams list" do
      let(:settings) do
        {
          webcam: {
            webcam_enabled: true,
            default_webcam: nil,
            stream_url: "/webcam/?action=stream",
            webcams: []
          }
        }
      end

      it "falls back to the legacy keys" do
        expect(webcam).to have_attributes(enabled: true, name: nil, stream_url: "/webcam/?action=stream")
      end
    end

    context "with the legacy webcam settings" do
      let(:settings) do
        {
          webcam: {
            webcam_enabled: false,
            stream_url: "http://octopi.local/webcam/?action=stream",
            snapshot_url: "http://127.0.0.1:8080/?action=snapshot",
            flip_h: true,
            flip_v: true,
            rotate90: false,
            stream_ratio: "4:3"
          }
        }
      end

      it "reads the legacy keys" do
        expect(webcam).to have_attributes(
          enabled: false,
          stream_url: "http://octopi.local/webcam/?action=stream",
          snapshot_url: "http://127.0.0.1:8080/?action=snapshot",
          name: nil,
          display_name: nil,
          flip_h: true,
          flip_v: true,
          rotate90: false,
          stream_ratio: "4:3"
        )
      end
    end

    context "when the URLs are empty" do
      let(:settings) { { webcam: { webcam_enabled: true, stream_url: "", snapshot_url: "" } } }

      it "returns nil URLs" do
        expect(webcam).to have_attributes(stream_url: nil, snapshot_url: nil)
      end
    end

    context "when the enabled flag is missing and there is a stream URL" do
      let(:settings) { { webcam: { stream_url: "/webcam/?action=stream" } } }

      it { is_expected.to have_attributes(enabled: true) }
    end

    context "when the enabled flag is missing and there is no stream URL" do
      let(:settings) { { webcam: {} } }

      it { is_expected.to have_attributes(enabled: false) }
    end

    context "without webcam settings" do
      let(:settings) { {} }

      it "is disabled and has no URLs" do
        expect(webcam).to have_attributes(enabled: false, stream_url: nil, snapshot_url: nil)
      end
    end
  end
end
