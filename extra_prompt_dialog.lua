local ChatGPTViewer = require("chatgptviewer")
local UIManager = require("ui/uimanager")
local Event = require("ui/event")
local _ = require("gettext")

local queryChatGPT = require("gpt_query")
local queryGemini = require("gemini_query")

local function runPrompt(provider, prompt)
  if provider == "gemini" then
    return queryGemini(prompt)
  end

  return queryChatGPT({
    {
      role = "system",
      content = "You are helpful, concise, and answer in Traditional Chinese unless asked otherwise.",
    },
    {
      role = "user",
      content = prompt,
    },
  })
end

local function showExtraPromptDialog(ui, highlightedText, button_config)
  local prompt_template = button_config.prompt or "{{highlight}}"
  local final_prompt = prompt_template:gsub("{{highlight}}", highlightedText)

  local answer = runPrompt(button_config.provider, final_prompt)
  local result_text = answer
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
end

return showExtraPromptDialog
