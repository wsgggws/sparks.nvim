local M = {}
local uv = vim.uv or vim.loop

-- 声音播放节流状态
local last_play_time = {
	insert = 0,
	delete = 0,
}
local sound_throttle_ms = 50 -- 50ms 内相同类型声音只播放一次

-- 播放声音
function M.play(sound_type, config)
	if not config.enable_sound then
		return
	end
	if sound_type == "insert" and not config.sound_on_insert then
		return
	end
	if sound_type == "delete" and not config.sound_on_delete then
		return
	end

	-- 声音节流：防止快速连续触发造成卡顿
	local now = uv.now()
	if now - last_play_time[sound_type] < sound_throttle_ms then
		return
	end
	last_play_time[sound_type] = now

	-- 检测操作系统并播放声音
	vim.schedule(function()
		local sound_cmd = nil
		local is_mac = vim.fn.has("mac") == 1
		local is_linux = vim.fn.has("unix") == 1 and vim.fn.has("mac") == 0
		local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1

		local sound_files = nil

		-- 处理 Sound Packs (如果未手动指定文件)
		if
			not config.sound_file_insert
			and not config.sound_file_delete
			and config.sound_pack
			and config.sound_pack ~= "default"
		then
			-- Future: Add logic to load sound pack files here
		end

		if sound_type == "insert" then
			sound_files = config.sound_file_insert
		elseif sound_type == "delete" then
			sound_files = config.sound_file_delete
		end

		-- 如果用户配置了自定义声音文件
		if sound_files and #sound_files > 0 then
			-- 确保是列表格式
			if type(sound_files) == "string" then
				sound_files = { sound_files }
			end

			-- 随机选择一个声音文件
			math.randomseed(os.time() + vim.loop.hrtime())
			local sound_file = sound_files[math.random(#sound_files)]

			if is_mac then
				sound_cmd = string.format("afplay '%s' -v %.2f &", sound_file, config.sound_volume)
			elseif is_linux then
				-- Linux 使用 paplay (PulseAuuvplay (ALSA)
				if vim.fn.executable("paplay") == 1 then
					sound_cmd = string.format("paplay '%s' &", sound_file)
				elseif vim.fn.executable("aplay") == 1 then
					sound_cmd = string.format("aplay '%s' &", sound_file)
				elseif vim.fn.executable("ffplay") == 1 then
					sound_cmd = string.format("ffplay -nodisp -autoexit -v 0 '%s' &", sound_file)
				end
			elseif is_windows then
				-- Windows 使用 PowerShell 播放
				local ps_script =
					string.format([[(New-Object Media.SoundPlayer '%s').PlaySync()]], sound_file:gsub("/", "\\"))
				sound_cmd = string.format('powershell -c "%s" &', ps_script)
			end
		else
			-- 使用系统默认声音
			if is_mac then
				-- macOS 系统默认音效
				local default_sound = sound_type == "insert" and "Pop" or "Bottle"
				sound_cmd =
					string.format("afplay /System/Library/Sounds/%s.aiff -v %.2f &", default_sound, config.sound_volume)
			elseif is_linux then
				-- Linux 系统默认音效
				if vim.fn.executable("paplay") == 1 then
					local default_sound = sound_type == "insert" and "message" or "bell"
					sound_cmd =
						string.format("paplay /usr/share/sounds/freedesktop/stereo/%s.oga 2>/dev/null &", default_sound)
				elseif vim.fn.executable("canberra-gtk-play") == 1 then
					-- 使用 libcanberra (Ubuntu/Debian)
					local event = sound_type == "insert" and "message" or "bell"
					sound_cmd = string.format("canberra-gtk-play -i %s &", event)
				elseif vim.fn.executable("beep") == 1 then
					-- 降级到终端蜂鸣音
					sound_cmd = "beep &"
				end
			elseif is_windows then
				-- Windows 系统默认音效
				local beep_freq = sound_type == "insert" and "800" or "400"
				sound_cmd = string.format('powershell -c "[Console]::Beep(%s, 100)" &', beep_freq)
			end
		end

		if sound_cmd then
			vim.fn.system(sound_cmd)
		end
	end)
end

return M
