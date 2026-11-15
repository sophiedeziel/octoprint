# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Timelapse::FileAttributes do
  describe ".included" do
    let(:timelapse_class) do
      Class.new do
        include Octoprint::Timelapse::FileAttributes

        auto_attr :url, type: String

        auto_initialize!
      end
    end

    it "declares the shared attributes before the including class's own" do
      expect(timelapse_class.auto_attrs.keys).to eq %i[name size bytes date extra url]
    end

    it "initializes the shared and own attributes" do
      timelapse = timelapse_class.new(name: "benchy.mp4", size: "2.0KB", bytes: 2048, date: "2026-11-15 00:52",
                                      url: "/downloads/timelapse/benchy.mp4")

      expect(timelapse).to have_attributes(name: "benchy.mp4", size: "2.0KB", bytes: 2048,
                                           date: "2026-11-15 00:52", url: "/downloads/timelapse/benchy.mp4")
    end

    it "makes the including class deserializable" do
      expect(timelapse_class.deserialize({ name: "benchy.mp4", fps: 25 }).extra).to eq({ fps: 25 })
    end

    it "keeps the attributes of each including class separate" do
      expect(Octoprint::Timelapse::Rendered.auto_attrs.keys).to include(:url)
      expect(Octoprint::Timelapse::Rendered.auto_attrs.keys).not_to include(:count)
      expect(Octoprint::Timelapse::Unrendered.auto_attrs.keys).to include(:count)
      expect(Octoprint::Timelapse::Unrendered.auto_attrs.keys).not_to include(:url)
    end
  end
end
