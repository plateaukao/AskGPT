local ChatGPTViewer = require("chatgptviewer")
local UIManager = require("ui/uimanager")
local _ = require("gettext")
local Event = require("ui/event")

local queryChatGPT = require("gpt_query")
local AskGPTConfig = require("config")

local function createResultText(highlightedText, message_history)
  local result_text = "\"" .. highlightedText .. "\"\n\n"
  for i = 3, #message_history do
    if message_history[i].role == "user" then
      result_text = result_text .. _("User: ") .. message_history[i].content .. "\n\n"
    else
      result_text = result_text .. message_history[i].content .. "\n\n"
    end
  end
  return result_text
end

local function showChatGPTDialog(ui, highlightedText, message_history)
  message_history = message_history or {
    {
      role = "system",
      content = "You are a good translator.",
    },
  }

  table.insert(message_history, {
    role = "user",
    content = "translate content in zh-hant:\n" .. highlightedText,
  })

  local result_text = ""
  local chatgpt_viewer

  local function handleAddToNote()
    local index = ui.highlight:saveHighlight(true)
    local a = ui.annotation.annotations[index]
    a.note = result_text
    ui:handleEvent(Event:new("AnnotationsModified", { a, nb_highlights_added = -1, nb_notes_added = 1 }))

    UIManager:close(chatgpt_viewer)
    ui.highlight:onClose()
  end

  local function handleNewQuestion(viewer, question)
    table.insert(message_history, { role = "user", content = question })
    local answer = queryChatGPT(message_history)
    table.insert(message_history, { role = "assistant", content = answer })
    result_text = createResultText(highlightedText, message_history)
    chatgpt_viewer = viewer:update(result_text)
  end

  chatgpt_viewer = ChatGPTViewer:new {
    ui = ui,
    title = _("GPT Translate"),
    text = _("Loading..."),
    onAskQuestion = handleNewQuestion,
    onAddToNote = handleAddToNote,
  }
  UIManager:show(chatgpt_viewer)

  local use_stream = AskGPTConfig.load().openai_stream
  local answer = queryChatGPT(message_history, use_stream and {
    on_delta = function(partial)
      local temp_history = {}
      for i = 1, #message_history do
        temp_history[i] = message_history[i]
      end
      table.insert(temp_history, { role = "assistant", content = partial })
      result_text = createResultText(highlightedText, temp_history)
      chatgpt_viewer = chatgpt_viewer:update(result_text)
    end,
  } or nil)

  table.insert(message_history, { role = "assistant", content = answer })
  result_text = createResultText(highlightedText, message_history)
  chatgpt_viewer = chatgpt_viewer:update(result_text)
end

return showChatGPTDialog
