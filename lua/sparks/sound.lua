local M = {}
local uv = vim.uv or vim.loop

local last_play = { insert = 0, delete = 0 }
local throttle_ms = 80

local function executable(name)
	return vim.fn.executable(name) == 1
end

local function choose_file(sound_type, config)
	local files = sound_type == "insert" and config.sound_file_insert or config.sound_file_delete
	if type(files) == "string" then
		return files
	end
	if type(files) == "table" and #files > 0 then
		return files[math.random(#files)]
	end
	return nil
end

local function command_for(sound_type, config)
	local file = choose_file(sound_type, config)
	local is_mac = vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1
	local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
	if is_mac and executable("afplay") then
		file = file or string.format("/System/Library/Sounds/%s.aiff", sound_type == "insert" and "Pop" or "Bottle")
		return {
			"afplay",
			"-v",
			tostring(config.sound_volume),
			"-r",
			string.format("%.2f", 2.5 + math.random() * 0.7),
			file,
		}
	end
	if is_windows and executable("powershell") then
		if file then
			local escaped = file:gsub("'", "''"):gsub("/", "\\")
			return {
				"powershell",
				"-NoProfile",
				"-Command",
				"(New-Object Media.SoundPlayer '" .. escaped .. "').PlaySync()",
			}
		end
		local frequency = sound_type == "insert" and 800 or 400
		return { "powershell", "-NoProfile", "-Command", string.format("[Console]::Beep(%d,100)", frequency) }
	end
	if file and executable("paplay") then
		return { "paplay", file }
	end
	if file and executable("aplay") then
		return { "aplay", file }
	end
	if file and executable("ffplay") then
		return { "ffplay", "-nodisp", "-autoexit", "-v", "0", file }
	end
	if not file and executable("canberra-gtk-play") then
		return { "canberra-gtk-play", "-i", sound_type == "insert" and "message" or "bell" }
	end
	if not file and executable("paplay") then
		local name = sound_type == "insert" and "message" or "bell"
		return { "paplay", "/usr/share/sounds/freedesktop/stereo/" .. name .. ".oga" }
	end
	return nil
end

function M.play(sound_type, config)
	if not config.enable_sound or config.sound_pack == "none" then
		return false
	end
	if sound_type == "insert" and not config.sound_on_insert then
		return false
	end
	if sound_type == "delete" and not config.sound_on_delete then
		return false
	end
	local now = uv.now()
	if now - last_play[sound_type] < throttle_ms then
		return false
	end
	last_play[sound_type] = now
	local command = command_for(sound_type, config)
	if not command then
		return false
	end
	vim.system(command, { detach = true }, function() end)
	return true
end

return M
