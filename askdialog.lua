local InputDialog = require("ui/widget/inputdialog")
local ChatGPTViewer = require("chatgptviewer")
local UIManager = require("ui/uimanager")
local Event = require("ui/event")
local _ = require("gettext")

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
  local title = ui.document:getProps().title or _("Unknown Title")
  local author = ui.document:getProps().authors or _("Unknown Author")
  message_history = message_history or {
    {
      role = "system",
      content = "You are an erudite, who is helpful, creative, clever. Answer as concisely as possible and in Traditional Chinese."
        .. "If there's no instructions, please explain the input in 100 words.",
    },
  }

  local input_dialog
  input_dialog = InputDialog:new {
    title = _("Ask a question about the highlighted text"),
    input_hint = _("Type your question here..."),
    input_type = "text",
    buttons = {
      {
        {
          text = _("Cancel"),
          callback = function()
            UIManager:close(input_dialog)
          end,
        },
        {
          text = _("Ask"),
          callback = function()
            local use_stream = AskGPTConfig.load().openai_stream
            if not use_stream then
              local InfoMessage = require("ui/widget/infomessage")
              UIManager:show(InfoMessage:new { text = _("Loading..."), timeout = 1 })
            end

            local context_message = {
              role = "user",
              content = "I'm reading something titled '" .. title .. "' by " .. author
                .. ". I have a question about the following highlighted text: " .. highlightedText,
            }
            table.insert(message_history, context_message)

            local question = input_dialog:getInputText()
            table.insert(message_history, { role = "user", content = question })
            UIManager:close(input_dialog)

            local result_text = _("Loading...")
            local chatgpt_viewer

            local function handleAddToNote()
              local index = ui.highlight:saveHighlight(true)
              local a = ui.annotation.annotations[index]
              a.note = result_text
              ui:handleEvent(Event:new("AnnotationsModified", { a, nb_highlights_added = -1, nb_notes_added = 1 }))

              UIManager:close(chatgpt_viewer)
              ui.highlight:onClose()
            end

            local function handleNewQuestion(viewer, followup_question)
              table.insert(message_history, { role = "user", content = followup_question })
              local answer = queryChatGPT(message_history, AskGPTConfig.load().openai_stream and {
                on_delta = function(partial)
                  local temp_history = {}
                  for i = 1, #message_history do
                    temp_history[i] = message_history[i]
                  end
                  table.insert(temp_history, { role = "assistant", content = partial })
                  result_text = createResultText(highlightedText, temp_history)
                  viewer:update(result_text)
                end,
              } or nil)
              table.insert(message_history, { role = "assistant", content = answer })
              result_text = createResultText(highlightedText, message_history)
              viewer:update(result_text)
            end

            chatgpt_viewer = ChatGPTViewer:new {
              ui = ui,
              title = _("AskGPT"),
              text = result_text,
              onAskQuestion = handleNewQuestion,
              onAddToNote = handleAddToNote,
            }
            UIManager:show(chatgpt_viewer)

            local answer = queryChatGPT(message_history, use_stream and {
              on_delta = function(partial)
                local temp_history = {}
                for i = 1, #message_history do
                  temp_history[i] = message_history[i]
                end
                table.insert(temp_history, { role = "assistant", content = partial })
                result_text = createResultText(highlightedText, temp_history)
                chatgpt_viewer:update(result_text)
              end,
            } or nil)

            table.insert(message_history, { role = "assistant", content = answer })
            result_text = createResultText(highlightedText, message_history)
            chatgpt_viewer:update(result_text)
          end,
        },
      },
    },
  }
  UIManager:show(input_dialog)
  input_dialog:onShowKeyboard()
end

return showChatGPTDialog
