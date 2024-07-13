local InputDialog = require("ui/widget/inputdialog")
local ChatGPTViewer = require("chatgptviewer")
local UIManager = require("ui/uimanager")
local TextBoxWidget = require("ui/widget/textboxwidget")
local PROMPTS = require("prompts")
local _ = require("gettext")

local Event = require("ui/event")

local queryChatGPT = require("gpt_query")

local function showChatGPTDialog(ui, highlightedText, message_history)
  local title, author =
      ui.document:getProps().title or _("Unknown Title"),
      ui.document:getProps().authors or _("Unknown Author")
  local message_history = message_history or {
    {
      role = "system",
      content =
      "You are a dictionary with high quality detail vocabulary definitions and examples.",
    },
  }
  prev_context, next_context = ui.highlight:getSelectedWordContext(10)
  -- Give context to the question
  local context_message = {
    role = "user",
    content = 
        prev_context .. "<<" .. highlightedText .. ">>" .. next_context .. "\n" ..
        PROMPTS.dict
  }
  table.insert(message_history, context_message)

  local answer = queryChatGPT(message_history)
  local function createResultText(highlightedText, answer)
    local result_text = 
      TextBoxWidget.PTF_HEADER .. 
      prev_context .. TextBoxWidget.PTF_BOLD_START .. highlightedText .. TextBoxWidget.PTF_BOLD_END .. next_context .. "\n\n" ..
      answer

    return result_text
  end

  local result_text = createResultText(highlightedText, answer)

  local function handleNewQuestion(chatgpt_viewer, question)
    local answer = queryChatGPT(message_history)
    result_text = createResultText(highlightedText, answer)

    -- Update the text and refresh the viewer
    chatgpt_viewer:update(result_text)
  end

  local chatgpt_viewer = nil

  local function handleAddToNote()
    -- ui.highlight:addNote(answer)
    local index = ui.highlight:saveHighlight(true)
    local a = ui.annotation.annotations[index]
    a.note = result_text
    ui:handleEvent(Event:new("AnnotationsModified",
                          { a, nb_highlights_added = -1, nb_notes_added = 1 }))

    UIManager:close(chatgpt_viewer)
    ui.highlight:onClose()
  end

  chatgpt_viewer = ChatGPTViewer:new {
    ui = ui,
    title = _("GPT Dictionary"),
    text = result_text,
    showAskQuestion = false,
    onAskQuestion = handleNewQuestion, -- Pass the callback function
    onAddToNote = handleAddToNote,
  }

  UIManager:show(chatgpt_viewer)
end

return showChatGPTDialog
