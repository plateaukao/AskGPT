local InputDialog = require("ui/widget/inputdialog")
local ChatGPTViewer = require("chatgptviewer")
local UIManager = require("ui/uimanager")
local _ = require("gettext")

local Event = require("ui/event")

local queryChatGPT = require("gpt_query")

local function showChatGPTDialog(ui, highlightedText, message_history)
  local message_history = message_history or {
    {
      role = "system",
      content =
      "You are a good translator.",
    },
  }

  -- Give context to the question
  local context_message = {
    role = "user",
    content = "translate content in zh-hant:\n" .. highlightedText
  }
  table.insert(message_history, context_message)

  local answer = queryChatGPT(message_history)
  -- Save the answer to the message history
  local answer_message = {
    role = "assistant",
    content = answer,
  }

  table.insert(message_history, answer_message)
  local result_text = answer

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


  local function handleNewQuestion(chatgpt_viewer, question)
    -- Add the new question to the message history
    table.insert(message_history, { role = "user", content = question })

    -- Send the query to ChatGPT with the updated message_history
    local answer = queryChatGPT(message_history)

    -- Add the answer to the message history
    table.insert(message_history, { role = "assistant", content = answer })

    -- Update the result text
    local result_text = createResultText(highlightedText, message_history)

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
    title = _("GPT Translate"),
    text = result_text,
    onAskQuestion = handleNewQuestion, -- Pass the callback function
    onAddToNote = handleAddToNote,
  }

  UIManager:show(chatgpt_viewer)
end

return showChatGPTDialog
