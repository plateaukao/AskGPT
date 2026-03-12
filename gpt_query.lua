local API_KEY = require("api_key")
local https = require("ssl.https")
local ltn12 = require("ltn12")
local json = require("json")
local AskGPTConfig = require("config")

local function decodeOpenAIDelta(payload)
  if payload == "[DONE]" then
    return nil
  end
  local ok, decoded = pcall(json.decode, payload)
  if not ok or not decoded or not decoded.choices or not decoded.choices[1] then
    return nil
  end
  local delta = decoded.choices[1].delta
  return delta and delta.content or nil
end

local function parseOpenAIStream(raw)
  local pieces = {}
  for line in raw:gmatch("[^\r\n]+") do
    local payload = line:match("^data:%s*(.+)$")
    local delta = payload and decodeOpenAIDelta(payload) or nil
    if delta then
      table.insert(pieces, delta)
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

  if use_stream and opts.on_delta then
    local partial = ""
    local pending = ""
    local stream_sink = function(chunk)
      if not chunk then
        return 1
      end
      table.insert(responseBody, chunk)
      pending = pending .. chunk
      while true do
        local line_end = pending:find("\n", 1, true)
        if not line_end then
          break
        end
        local line = pending:sub(1, line_end - 1):gsub("\r$", "")
        pending = pending:sub(line_end + 1)
        local payload = line:match("^data:%s*(.+)$")
        local delta = payload and decodeOpenAIDelta(payload) or nil
        if delta then
          partial = partial .. delta
          opts.on_delta(partial)
        end
      end
      return 1
    end

    local _, code = https.request {
      url = api_url,
      method = "POST",
      headers = headers,
      source = ltn12.source.string(requestBody),
      sink = stream_sink,
    }

    if code ~= 200 then
      error("Error querying ChatGPT API: " .. tostring(code))
    end

    return partial ~= "" and partial or parseOpenAIStream(table.concat(responseBody))
  end

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
