local InputDialog = require("ui/widget/inputdialog")
local ChatGPTViewer = require("chatgptviewer")
local UIManager = require("ui/uimanager")
local Event = require("ui/event")

local _ = require("gettext")

local queryChatGPT = require("gpt_query")

local function showChatGPTDialog(ui, highlightedText, message_history)
  local title, author =
      ui.document:getProps().title or _("Unknown Title"),
      ui.document:getProps().authors or _("Unknown Author")
  local message_history = message_history or {
    {
      role = "system",
      content =
      "You are an erudite, who is helpful, creative, clever. Answer as concisely as possible and in Traditional Chinese." ..
      "If there's no instructions, please explain the input in 100 words.",
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
            local InfoMessage = require("ui/widget/infomessage")
            local loading = InfoMessage:new {
              text = _("Loading..."),
              timeout = 1,
            }
            UIManager:show(loading)

            -- Give context to the question
            local context_message = {
              role = "user",
              content = "I'm reading something titled '" ..
                  title ..
                  "' by " .. author .. ". I have a question about the following highlighted text: " .. highlightedText,
            }
            table.insert(message_history, context_message)

            -- Ask the question
            local question = input_dialog:getInputText()
            local question_message = {
              role = "user",
              content = question,
            }
            table.insert(message_history, question_message)

            local answer = queryChatGPT(message_history)
            -- Save the answer to the message history
            local answer_message = {
              role = "assistant",
              content = answer,
            }

            table.insert(message_history, answer_message)
            UIManager:close(input_dialog)
            local result_text = _("Highlighted text: ") .. "\"" .. highlightedText .. "\"" ..
                "\n\n" .. _("User: ") .. question ..
                "\n\n" .. _("ChatGPT: ") .. answer .. "\n\n"

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
              result_text = createResultText(highlightedText, message_history)

              -- Update the text and refresh the viewer
              chatgpt_viewer:update(result_text)
            end

            local chatgpt_viewer = nil

            local function handleAddToNote()
              -- ui.highlight:addNote(result_text)
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
              title = _("AskGPT"),
              text = result_text,
              onAskQuestion = handleNewQuestion, -- Pass the callback function
              onAddToNote = handleAddToNote,
            }

            UIManager:show(chatgpt_viewer)
          end,
        },
      },
    },
  }
  UIManager:show(input_dialog)
  input_dialog:onShowKeyboard()
end

return showChatGPTDialog
