# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Files::Legacy do
  def request(http_method, path, query: {}, body: nil)
    Octoprint::ApiRequest.new(http_method: http_method, path: path, query: query, body: body)
  end

  # Entries as returned by an OctoPrint 1.11.8 server
  let(:local_entry) do
    {
      date: 1_794_809_464,
      display: "test_file.gcode",
      hash: "42a10b291437f41e1834614c5841837260e57f45",
      name: "test_file.gcode",
      origin: "local",
      path: "test_file.gcode",
      refs: {
        download: "http://127.0.0.1:5040/downloads/files/local/test_file.gcode",
        resource: "http://127.0.0.1:5040/api/files/local/test_file.gcode"
      },
      size: 981,
      type: "machinecode",
      type_path: %w[machinecode gcode],
      user: "admin"
    }
  end

  let(:sdcard_entry) do
    {
      display: "/test_f-1.gco",
      name: "test_f-1.gco",
      origin: "sdcard",
      path: "test_f-1.gco",
      refs: { resource: "http://127.0.0.1:5040/api/files/sdcard/test_f-1.gco" },
      size: 409,
      type: "machinecode",
      type_path: %w[machinecode gcode]
    }
  end

  let(:printer_entry) do
    sdcard_entry.merge(
      origin: "printer",
      refs: { resource: "http://127.0.0.1:5040/api/files/printer/test_f-1.gco" }
    )
  end

  it "is the Files resource's legacy converter" do
    expect(Octoprint::Files.legacy_converter).to be(described_class)
  end

  describe ".to_request" do
    it "sends the printer storage as sdcard" do
      converted = described_class.to_request(request(:get, "/api/files/printer"))

      expect(converted.path).to eq("/api/files/sdcard")
    end

    it "keeps the trailing slash of the storage's root folder" do
      converted = described_class.to_request(request(:post, "/api/files/printer/"))

      expect(converted.path).to eq("/api/files/sdcard/")
    end

    it "renames the storage of a file path and keeps the query and body" do
      original = request(:post, "/api/files/printer/a/b.gco", query: { recursive: true }, body: { command: "select" })

      converted = described_class.to_request(original)

      expect(converted).to eq(request(:post, "/api/files/sdcard/a/b.gco",
                                      query: { recursive: true }, body: { command: "select" }))
    end

    it "leaves a local file named like the storage alone" do
      original = request(:get, "/api/files/local/printer.gcode")

      expect(described_class.to_request(original)).to be(original)
    end

    it "leaves a path that only starts with printer alone" do
      original = request(:get, "/api/files/printerx")

      expect(described_class.to_request(original)).to be(original)
    end

    it "leaves the local storage alone" do
      original = request(:get, "/api/files/local")

      expect(described_class.to_request(original)).to be(original)
    end

    it "leaves GET /api/files alone" do
      original = request(:get, "/api/files")

      expect(described_class.to_request(original)).to be(original)
    end
  end

  describe ".from_response" do
    describe "GET /api/files" do
      let(:list_request) { request(:get, "/api/files") }

      it "splits the files by storage" do
        response = { files: [local_entry, sdcard_entry], free: 491_528_597_504, total: 994_662_584_320 }

        expect(described_class.from_response(response, list_request)).to eq(
          local: {
            key: "local",
            files: [local_entry],
            usage: { free: 491_528_597_504, total: 994_662_584_320 }
          },
          printer: {
            key: "printer",
            files: [printer_entry]
          }
        )
      end

      it "has only the local storage when the printer has no files" do
        response = { files: [local_entry], free: 491_528_597_504, total: 994_662_584_320 }

        expect(described_class.from_response(response, list_request)).to eq(
          local: {
            key: "local",
            files: [local_entry],
            usage: { free: 491_528_597_504, total: 994_662_584_320 }
          }
        )
      end

      it "has an empty local storage for an empty listing" do
        response = { files: [], free: 491_528_597_504, total: 994_662_584_320 }

        expect(described_class.from_response(response, list_request)).to eq(
          local: { key: "local", files: [], usage: { free: 491_528_597_504, total: 994_662_584_320 } }
        )
      end

      it "groups files already reported with the printer origin" do
        # An OctoPrint 2.0 server answering a client that didn't send the API version header
        response = { files: [local_entry, printer_entry], free: 1, total: 2 }

        result = described_class.from_response(response, list_request)

        expect(result.keys).to eq(%i[local printer])
        expect(result[:printer]).to eq(key: "printer", files: [printer_entry])
      end

      it "can be deserialized into Files by storage" do
        response = { files: [local_entry, sdcard_entry], free: 491_528_597_504, total: 994_662_584_320 }

        storages = described_class.from_response(response, list_request)
                                  .transform_values { |storage| Octoprint::Files.deserialize(storage) }

        expect(storages[:local].free).to eq(491_528_597_504)
        expect(storages[:local].files.first.user).to eq("admin")
        expect(storages[:printer].files.first.origin).to eq(Octoprint::Location::Printer)
        expect(storages[:printer].usage).to be_nil
      end
    end

    describe "GET /api/files/<storage>" do
      it "reshapes the local storage" do
        response = { files: [], free: 491_531_599_872, total: 994_662_584_320 }

        expect(described_class.from_response(response, request(:get, "/api/files/local"))).to eq(
          key: "local", files: [], usage: { free: 491_531_599_872, total: 994_662_584_320 }
        )
      end

      it "reshapes the printer storage, without usage" do
        response = { files: [sdcard_entry] }

        expect(described_class.from_response(response, request(:get, "/api/files/printer"))).to eq(
          key: "printer", files: [printer_entry]
        )
      end

      it "keeps the query out of the storage detection" do
        response = { files: [], free: 1, total: 2 }
        get = request(:get, "/api/files/local", query: { recursive: true })

        expect(described_class.from_response(response, get))
          .to eq(key: "local", files: [], usage: { free: 1, total: 2 })
      end
    end

    describe "GET /api/files/<storage>/<file>" do
      it "only renames the printer storage" do
        response = sdcard_entry

        expect(described_class.from_response(response, request(:get, "/api/files/printer/test_f-1.gco")))
          .to eq(printer_entry)
      end

      it "leaves a local file alone" do
        expect(described_class.from_response(local_entry, request(:get, "/api/files/local/test_file.gcode")))
          .to eq(local_entry)
      end
    end

    describe "POST upload" do
      let(:local_upload) do
        {
          name: "test_file.gcode",
          origin: "local",
          path: "test_file.gcode",
          refs: {
            download: "http://127.0.0.1:5040/downloads/files/local/test_file.gcode",
            resource: "http://127.0.0.1:5040/api/files/local/test_file.gcode"
          }
        }
      end

      it "picks the printer entry of an upload to the printer" do
        response = {
          done: false,
          effective_print: false,
          effective_select: false,
          files: {
            local: local_upload,
            sdcard: {
              name: "/test_f~1.gco",
              origin: "sdcard",
              path: "/test_f~1.gco",
              refs: { resource: "http://127.0.0.1:5040/api/files/sdcard//test_f~1.gco" }
            }
          }
        }

        result = described_class.from_response(response, request(:post, "/api/files/printer"))

        expect(result).to eq(
          done: false,
          effective_print: false,
          effective_select: false,
          file: {
            name: "/test_f~1.gco",
            origin: "printer",
            path: "/test_f~1.gco",
            refs: { resource: "http://127.0.0.1:5040/api/files/printer//test_f~1.gco" }
          }
        )
        expect(result).not_to have_key(:files)
      end

      it "picks the local entry of a local upload" do
        response = { done: true, effective_print: false, effective_select: false, files: { local: local_upload } }

        expect(described_class.from_response(response, request(:post, "/api/files/local"))).to eq(
          done: true, effective_print: false, effective_select: false, file: local_upload
        )
      end

      it "falls back to the first entry for an unexpected storage" do
        response = { done: true, files: { usb: local_upload } }

        expect(described_class.from_response(response, request(:post, "/api/files/local"))).to eq(
          done: true, file: local_upload
        )
      end

      it "can be deserialized into an OperationResult" do
        response = { done: true, effective_print: false, effective_select: false, files: { local: local_upload } }

        result = Octoprint::Files::OperationResult.deserialize(
          described_class.from_response(response, request(:post, "/api/files/local"))
        )

        expect(result.file).to be_a(Octoprint::Files::File)
        expect(result.file.origin).to eq(Octoprint::Location::Local)
      end
    end

    describe "POST create folder" do
      it "leaves the response alone" do
        response = {
          done: true,
          folder: {
            name: "test",
            origin: "local",
            path: "test",
            refs: { resource: "http://127.0.0.1:5040/api/files/local/test" }
          }
        }

        expect(described_class.from_response(response, request(:post, "/api/files/local"))).to eq(response)
      end
    end

    describe "POST file command" do
      it "leaves a copy result alone" do
        response = {
          name: "test_file.gcode",
          origin: "local",
          path: "test_folder/copied_file.gcode",
          refs: {
            download: "http://127.0.0.1:5040/downloads/files/local/test_folder/copied_file.gcode",
            resource: "http://127.0.0.1:5040/api/files/local/test_folder/copied_file.gcode"
          }
        }
        copy = request(:post, "/api/files/local/test_folder/test_file.gcode", body: { command: "copy" })

        expect(described_class.from_response(response, copy)).to eq(response)
      end

      it "passes a 204 No Content through" do
        expect(described_class.from_response(true, request(:post, "/api/files/printer/A.GCO"))).to be(true)
      end
    end

    describe "renaming sdcard to printer" do
      let(:other_request) { request(:delete, "/api/files/printer/A.GCO") }

      it "renames inside arrays" do
        response = [sdcard_entry, [sdcard_entry]]

        expect(described_class.from_response(response, other_request)).to eq([printer_entry, [printer_entry]])
      end

      it "renames sdcard keys" do
        response = { sdcard: { origin: "sdcard" }, local: { origin: "local" } }

        expect(described_class.from_response(response, other_request)).to eq(
          printer: { origin: "printer" }, local: { origin: "local" }
        )
      end

      it "renames nested children" do
        response = { name: "dir", origin: "sdcard", children: [sdcard_entry] }

        expect(described_class.from_response(response, other_request)).to eq(
          name: "dir", origin: "printer", children: [printer_entry]
        )
      end

      it "doesn't rewrite strings outside refs" do
        response = { display: "http://host/api/files/sdcard/x.gco", name: "sdcard", origin: "local" }

        expect(described_class.from_response(response, other_request)).to eq(response)
      end

      it "leaves non-string refs alone" do
        response = { refs: { resource: nil, thumbnails: { "16x16" => "/files/sdcard/x" } } }

        expect(described_class.from_response(response, other_request)).to eq(response)
      end

      it "only renames the sdcard path segment of refs URLs" do
        response = {
          refs: {
            resource: "http://host/api/files/sdcard",
            download: "http://host/downloads/files/sdcardx/a.gco"
          }
        }

        expect(described_class.from_response(response, other_request)).to eq(
          refs: { resource: "http://host/api/files/printer", download: "http://host/downloads/files/sdcardx/a.gco" }
        )
      end

      it "passes non-collection values through" do
        expect(described_class.from_response("sdcard", other_request)).to eq("sdcard")
        expect(described_class.from_response(nil, other_request)).to be_nil
      end
    end
  end
end
