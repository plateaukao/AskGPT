local API_KEY = require("api_key")
local https = require("ssl.https")
local ltn12 = require("ltn12")
local json = require("json")
local AskGPTConfig = require("config")

local function parseOpenAIStream(raw)
  local pieces = {}
  for line in raw:gmatch("[^\r\n]+") do
    local payload = line:match("^data:%s*(.+)$")
    if payload and payload ~= "[DONE]" then
      local ok, decoded = pcall(json.decode, payload)
      if ok and decoded and decoded.choices and decoded.choices[1] and decoded.choices[1].delta then
        local delta = decoded.choices[1].delta.content
        if delta then
          table.insert(pieces, delta)
        end
      end
    end
  end
  return table.concat(pieces)
end

local function queryChatGPT(message_history, opts)
  opts = opts or {}
  local api_key = API_KEY.key
  local api_url = "https://api.openai.com/v1/chat/completions"

  local config = AskGPTConfig.load()
  local use_stream = opts.stream
  if use_stream == nil then
    use_stream = config.openai_stream
  end

  local headers = {
    ["Content-Type"] = "application/json",
    ["Authorization"] = "Bearer " .. api_key,
  }

  local requestBody = json.encode({
    model = opts.model or "gpt-4.1-mini",
    messages = message_history,
    stream = use_stream,
  })

  local responseBody = {}

  local _, code = https.request {
    url = api_url,
    method = "POST",
    headers = headers,
    source = ltn12.source.string(requestBody),
    sink = ltn12.sink.table(responseBody),
  }

  if code ~= 200 then
    error("Error querying ChatGPT API: " .. tostring(code))
  end

  local raw = table.concat(responseBody)
  if use_stream then
    return parseOpenAIStream(raw)
  end

  local response = json.decode(raw)
  return response.choices[1].message.content
end

return queryChatGPT
