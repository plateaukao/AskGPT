local json = require("json")

local DEFAULTS = {
  openai_stream = false,
  gemini_stream = false,
  extra_buttons = {},
}

local function getConfigPath()
  local ok, DataStorage = pcall(require, "datastorage")
  if ok and DataStorage and DataStorage.getDataDir then
    return DataStorage:getDataDir() .. "/askgpt_config.json"
  end
  return "askgpt_config.json"
end

local function shallowCopy(tbl)
  local copied = {}
  for k, v in pairs(tbl) do
    copied[k] = v
  end
  return copied
end

local function normalize(config)
  local merged = shallowCopy(DEFAULTS)
  if type(config) ~= "table" then
    return merged
  end
  if type(config.openai_stream) == "boolean" then
    merged.openai_stream = config.openai_stream
  end
  if type(config.gemini_stream) == "boolean" then
    merged.gemini_stream = config.gemini_stream
  end
  if type(config.extra_buttons) == "table" then
    merged.extra_buttons = config.extra_buttons
  end
  return merged
end

local function loadConfig()
  local path = getConfigPath()
  local file = io.open(path, "r")
  if not file then
    return normalize(nil)
  end

  local raw = file:read("*a")
  file:close()
  local ok, decoded = pcall(json.decode, raw)
  if not ok then
    return normalize(nil)
  end

  return normalize(decoded)
end

local function saveConfig(config)
  local normalized = normalize(config)
  local path = getConfigPath()
  local file, err = io.open(path, "w")
  if not file then
    return nil, err
  end
  file:write(json.encode(normalized))
  file:close()
  return true
end

local function getTemplate()
  return json.encode({
    openai_stream = false,
    gemini_stream = false,
    extra_buttons = {
      {
        id = "example_openai",
        text = "Explain simply",
        provider = "openai",
        prompt = "Please explain the following highlight in simple Traditional Chinese:\n{{highlight}}",
      },
      {
        id = "example_gemini",
        text = "Find key points",
        provider = "gemini",
        prompt = "Summarize key points from this highlight:\n{{highlight}}",
      },
    },
  })
end

return {
  load = loadConfig,
  save = saveConfig,
  normalize = normalize,
  template = getTemplate,
  path = getConfigPath,
}
