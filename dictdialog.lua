local ChatGPTViewer = require("chatgptviewer")
local UIManager = require("ui/uimanager")
local TextBoxWidget = require("ui/widget/textboxwidget")
local PROMPTS = require("prompts")
local _ = require("gettext")
local Event = require("ui/event")

local queryChatGPT = require("gpt_query")
local AskGPTConfig = require("config")

local function showChatGPTDialog(ui, highlightedText, message_history)
  message_history = message_history or {
    {
      role = "system",
      content = "You are a dictionary with high quality detail vocabulary definitions and examples.",
    },
  }

  local prev_context, next_context = ui.highlight:getSelectedWordContext(10)
  local context_message = {
    role = "user",
    content = prev_context .. "<<" .. highlightedText .. ">>" .. next_context .. "\n" .. PROMPTS.dict,
  }
  table.insert(message_history, context_message)

  local function createResultText(answer)
    return TextBoxWidget.PTF_HEADER .. (answer or "")
  end

  local use_stream = AskGPTConfig.load().openai_stream
  local result_text = createResultText("")
  local chatgpt_viewer

  local function handleAddToNote()
    local index = ui.highlight:saveHighlight(true)
    local a = ui.annotation.annotations[index]
    a.note = result_text
    ui:handleEvent(Event:new("AnnotationsModified", { a, nb_highlights_added = -1, nb_notes_added = 1 }))

    UIManager:close(chatgpt_viewer)
    ui.highlight:onClose()
  end

  chatgpt_viewer = ChatGPTViewer:new {
    ui = ui,
    title = _("GPT Dictionary"),
    text = result_text,
    showAskQuestion = false,
    onAddToNote = handleAddToNote,
  }
  UIManager:show(chatgpt_viewer)

  local answer = queryChatGPT(message_history, use_stream and {
    on_delta = function(partial)
      result_text = createResultText(partial)
      chatgpt_viewer = chatgpt_viewer:update(result_text)
    end,
  } or nil)

  result_text = createResultText(answer)
  chatgpt_viewer = chatgpt_viewer:update(result_text)
end

return showChatGPTDialog
