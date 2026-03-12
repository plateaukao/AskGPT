local ChatGPTViewer = require("chatgptviewer")
local UIManager = require("ui/uimanager")
local Event = require("ui/event")
local _ = require("gettext")

local queryChatGPT = require("gpt_query")
local queryGemini = require("gemini_query")
local AskGPTConfig = require("config")

local function showExtraPromptDialog(ui, highlightedText, button_config)
  local prompt_template = button_config.prompt or "{{highlight}}"
  local final_prompt = prompt_template:gsub("{{highlight}}", highlightedText)

  local result_text = _("Loading...")
  local viewer

  local function handleAddToNote()
    local index = ui.highlight:saveHighlight(true)
    local a = ui.annotation.annotations[index]
    a.note = result_text
    ui:handleEvent(Event:new("AnnotationsModified", { a, nb_highlights_added = -1, nb_notes_added = 1 }))

    UIManager:close(viewer)
    ui.highlight:onClose()
  end

  viewer = ChatGPTViewer:new {
    ui = ui,
    title = button_config.text or _("AskGPT Custom"),
    text = result_text,
    showAskQuestion = false,
    onAddToNote = handleAddToNote,
  }
  UIManager:show(viewer)

  if button_config.provider == "gemini" then
    local answer = queryGemini(final_prompt, AskGPTConfig.load().gemini_stream and {
      on_delta = function(partial)
        result_text = partial
        viewer = viewer:update(result_text)
      end,
    } or nil)
    result_text = answer
    viewer = viewer:update(result_text)
    return
  end

  local answer = queryChatGPT({
    {
      role = "system",
      content = "You are helpful, concise, and answer in Traditional Chinese unless asked otherwise.",
    },
    {
      role = "user",
      content = final_prompt,
    },
  }, AskGPTConfig.load().openai_stream and {
    on_delta = function(partial)
      result_text = partial
      viewer = viewer:update(result_text)
    end,
  } or nil)

  result_text = answer
  viewer = viewer:update(result_text)
end

return showExtraPromptDialog
