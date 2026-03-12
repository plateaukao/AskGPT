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

local function parseGeminiStream(raw)
  local pieces = {}
  for line in raw:gmatch("[^\r\n]+") do
    local payload = line:match("^data:%s*(.+)$")
    if payload and payload ~= "[DONE]" then
      local ok, decoded = pcall(json.decode, payload)
      if ok and decoded and decoded.candidates and decoded.candidates[1] then
        table.insert(pieces, extractGeminiText(decoded.candidates[1]))
      end
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

  local method_name = use_stream and "streamGenerateContent?alt=sse" or "generateContent"
  local api_url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:"
    .. method_name .. "&key=" .. API_KEY.key

  if not use_stream then
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
