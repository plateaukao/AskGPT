local InputDialog = require("ui/widget/inputdialog")
local ChatGPTViewer = require("chatgptviewer")
local UIManager = require("ui/uimanager")
local TextBoxWidget = require("ui/widget/textboxwidget")
local PROMPTS = require("prompts")
local _ = require("gettext")
local Event = require("ui/event")

local queryGemini = require("gemini_query")

local function showGeminiDictDialog(ui, highlightedText, message_history)
  prev_context, next_context = ui.highlight:getSelectedWordContext(10)

  local context_message = prev_context .. "<<" .. highlightedText .. ">>" .. next_context .. "\n" ..
        PROMPTS.dict

  local success, result = pcall(function()
    return queryGemini(context_message)
  end)
  if success then
    answer = result
  else
    answer = "Error: " .. result
  end

  local function createResultText(highlightedText, answer)
    local result_text = 
      TextBoxWidget.PTF_HEADER .. 
      prev_context .. TextBoxWidget.PTF_BOLD_START .. highlightedText .. TextBoxWidget.PTF_BOLD_END .. next_context .. "\n\n" ..
      answer

    return result_text
  end

  local result_text = createResultText(highlightedText, answer)

  local function handleNewQuestion(chatgpt_viewer, question)
    local answer = queryGemini(context_message)
    local result_text = createResultText(highlightedText, answer)

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
    title = _("Gemini Dictionary"),
    text = result_text,
    showAskQuestion = false,
    onAskQuestion = handleNewQuestion, -- Pass the callback function
    onAddToNote = handleAddToNote,
  }

  UIManager:show(chatgpt_viewer)
end

return showGeminiDictDialog
