local M = {}

function M:peek(job)
  local start, cache = os.clock(), ya.file_cache(job)
	if not cache or self:preload(job) ~= 1 then
		return
	end

	ya.sleep(math.max(0, PREVIEW.image_delay / 1000 + start - os.clock()))
	ya.image_show(cache, job.area)
	ya.preview_widgets(job, {})
end

function M:seek(job) end

function M:preload(job)
  local cache = ya.file_cache(job)
  if not cache or fs.cha(cache) then
    return 1
  end

  local output = Command("unzip")
    :args({
      "-p",
      tostring(job.file.url),
      "mergedimage.png"
    })
    :stdout(Command.PIPED)
    :stderr(Command.PIPED)
    :output()

  if not output then
    return 0
  elseif not output.status.success then
    return 0
  end

  return fs.write(cache, output.stdout) and 1 or 2
end


return M
