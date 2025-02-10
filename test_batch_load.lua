util = {}
function util.scandir(dir)
    return {
        "1_bass_1.wav",
        "2_bass_1.wav",
        "1_lead_2.wav",
        "2_lead_2.wav",
        "3_lead_2.wav",
        "random_file.wav",
        "1_drums_3.wav"
    }
end

function get_length_audio(path)
    if path:match("%.wav$") then
        return 1.0 -- return 1 second for all wav files
    end
    return 0
end

tp = {
    [1] = {
        s = 0,
        e = 100,
        splice = {
            [1] = { s = 0, e = 0 },
            [2] = { s = 0, e = 0 },
            [3] = { s = 0, e = 0 },
            [4] = { s = 0, e = 0 },
            [5] = { s = 0, e = 0 },
            [6] = { s = 0, e = 0 },
            [7] = { s = 0, e = 0 },
            [8] = { s = 0, e = 0 }
        }
    }
}

function load_audio(path, i, s, l)
    print(string.format("loading %s into splice %d", path, s))
    tp[i].splice[s].l = l
    tp[i].splice[s].e = tp[i].splice[s].s + l
    tp[i].splice[s].name = path:match("[^/]*$")
    return tp[i].splice[s].e + 0.1
end

function show_message(msg)
    print("message:", msg)
end

function load_batch(path, i, s, n)
    local filepath = path:match("[^/]*$")
    local folder = path:match("(.*[/])") or ""
    local files = util.scandir(folder)
    local splice_s = s == 1 and tp[i].s or (tp[i].splice[s - 1].e + 0.1)

    local selected_splice_num, selected_sample_name = filepath:match("(%d+)_(.+)")
    if not selected_splice_num or not selected_sample_name then
        print("selected file doesn't match pattern <splice_number>_<sample_name>")
        return
    end

    local sample_files = {}
    for f, filename in ipairs(files) do
        local splice_num, sample_name = filename:match("(%d+)_(.+)")
        if splice_num and sample_name == selected_sample_name then
            table.insert(sample_files, {
                filename = filename,
                splice_num = tonumber(splice_num),
                index = f
            })
        end
    end

    table.sort(sample_files, function(a, b) return a.splice_num < b.splice_num end)

    local s = s
    for _, file_info in ipairs(sample_files) do
        if s <= 8 then
            local filepath = folder .. file_info.filename
            local file_l = get_length_audio(filepath)
            if file_l > 0 then
                if splice_s + file_l <= tp[i].e then
                    tp[i].splice[s].s = splice_s
                    splice_s = load_audio(filepath, i, s, file_l)
                    s = s + 1
                else
                    print(files[file_info.index] .. " too long - can't populate further")
                    show_message("splice   " .. s .. "   too long")
                    goto done
                end
            else
                print(files[file_info.index] .. " is not a sound file")
            end
        else
            print("no file - out of bounds")
        end
    end

    ::done::
    print("\nfinal splice state:")
    for j = 1, 8 do
        if tp[i].splice[j].name then
            print(string.format("Splice %d: %s", j, tp[i].splice[j].name))
        end
    end
end

print("\ntest 1: loading lead samples starting from splice 1")
print("(should load 1_lead_2.wav, 2_lead_2.wav, 3_lead_2.wav in order)")
load_batch("1_lead_2.wav", 1, 1, 8)

print("\ntest 2: loading bass samples starting from splice 4")
print("(should load 1_bass_1.wav, 2_bass_1.wav in order)")
load_batch("1_bass_1.wav", 1, 4, 8)

print("\ntest 3: loading with invalid filename")
print("(should show error message)")
load_batch("random_file.wav", 1, 1, 8)

print("\ntest 4: loading drums (single file)")
print("(should load just 1_drums_3.wav)")
load_batch("1_drums_3.wav", 1, 1, 8)
