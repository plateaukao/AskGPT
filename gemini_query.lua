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
            parts = {{ 
              text = context_message ,
            }}
        }
    },
    safety_settings = {
      { category = "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold = "BLOCK_ONLY_HIGH" },
      { category = "HARM_CATEGORY_HATE_SPEECH", threshold = "BLOCK_ONLY_HIGH" },
      { category = "HARM_CATEGORY_HARASSMENT", threshold = "BLOCK_ONLY_HIGH" },
      { category = "HARM_CATEGORY_DANGEROUS_CONTENT", threshold = "BLOCK_ONLY_HIGH" }
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
    return "Error querying Gemini API: " .. code
  end

  local response = json.decode(table.concat(responseBody))
  return response.candidates[1].content.parts[1].text
  -- return table.concat(responseBody)
end

return queryGemini
