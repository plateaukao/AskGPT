local API_KEY = require("gemini_api_key")
local https = require("ssl.https")
local ltn12 = require("ltn12")
local json = require("json")
local AskGPTConfig = require("config")

local function extractGeminiText(candidate)
  if not candidate or not candidate.content or not candidate.content.parts then
    return ""
  end

  local parts = {}
  for _, part in ipairs(candidate.content.parts) do
    if part.text then
      table.insert(parts, part.text)
    end
  end
  return table.concat(parts)
end

local function decodeGeminiDelta(payload)
  if payload == "[DONE]" then
    return nil
  end
  local ok, decoded = pcall(json.decode, payload)
  if not ok or not decoded or not decoded.candidates or not decoded.candidates[1] then
    return nil
  end
  return extractGeminiText(decoded.candidates[1])
end

local function parseGeminiStream(raw)
  local pieces = {}
  for line in raw:gmatch("[^\r\n]+") do
    local payload = line:match("^data:%s*(.+)$")
    local delta = payload and decodeGeminiDelta(payload) or nil
    if delta and delta ~= "" then
      table.insert(pieces, delta)
    end
  end
  return table.concat(pieces)
end

local function queryGemini(context_message, opts)
  opts = opts or {}
  local config = AskGPTConfig.load()
  local use_stream = opts.stream
  if use_stream == nil then
    use_stream = config.gemini_stream
  end

  local api_url
  if use_stream then
    api_url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:streamGenerateContent?alt=sse&key="
      .. API_KEY.key
  else
    api_url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=" .. API_KEY.key
  end

  local headers = {
    ["Content-Type"] = "application/json",
  }

  local data = {
    contents = {
      {
        parts = {
          {
            text = context_message,
          },
        },
      },
    },
    safety_settings = {
      { category = "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold = "BLOCK_NONE" },
      { category = "HARM_CATEGORY_HATE_SPEECH", threshold = "BLOCK_NONE" },
      { category = "HARM_CATEGORY_HARASSMENT", threshold = "BLOCK_NONE" },
      { category = "HARM_CATEGORY_DANGEROUS_CONTENT", threshold = "BLOCK_NONE" },
    },
  }

  local requestBody = json.encode(data)
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
        local delta = payload and decodeGeminiDelta(payload) or nil
        if delta and delta ~= "" then
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
      return "Error querying Gemini API: " .. tostring(code)
    end

    return partial ~= "" and partial or parseGeminiStream(table.concat(responseBody))
  end

  local _, code = https.request {
    url = api_url,
    method = "POST",
    headers = headers,
    source = ltn12.source.string(requestBody),
    sink = ltn12.sink.table(responseBody),
  }

  if code ~= 200 then
    return "Error querying Gemini API: " .. tostring(code)
  end

  local raw = table.concat(responseBody)
  if use_stream then
    return parseGeminiStream(raw)
  end

  local response = json.decode(raw)
  return extractGeminiText(response.candidates[1])
end

return queryGemini
