local API_KEY = require("gemini_api_key")
local https = require("ssl.https")
local ltn12 = require("ltn12")
local json = require("json")

local function queryGemini(context_message)
  local api_url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=" .. API_KEY.key

  local headers = {
    ["Content-Type"] = "application/json",
  }

  local data = {
    contents = {
        {
            parts = {{ text = context_message }}
        }
    }
  }

  local requestBody = json.encode(data)

  local responseBody = {}

  local res, code, responseHeaders = https.request {
    url = api_url,
    method = "POST",
    headers = headers,
    source = ltn12.source.string(requestBody),
    sink = ltn12.sink.table(responseBody),
  }

  if code ~= 200 then
    error("Error querying ChatGPT API: " .. code)
  end

  local response = json.decode(table.concat(responseBody))
  return response.candidates[1].content.parts[1].text
end

return queryGemini
