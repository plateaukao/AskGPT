local InputDialog = require("ui/widget/inputdialog")
local ChatGPTViewer = require("chatgptviewer")
local UIManager = require("ui/uimanager")
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
      "The following is a conversation with an AI assistant. The assistant is helpful, creative, clever, and very friendly. Answer as concisely as possible and in Traditional Chinese.",
    },
  }

  prev_context, next_context = ui.highlight:getSelectedWordContext(15)
            -- Give context to the question
            local context_message = {
              role = "user",
              content = 
                  "完整句子: " .. prev_context .. "<<" .. highlightedText .. ">>" .. "\n" ..
                  "將上述句子中 <<>> 中的內容 1. 翻譯成 zh-TW\n" ..
                  "2. 顯示單字原型;如果是日文單字，則顯示漢字拼法 (原本語言)\n" ..
                  "3. 舉一個新的例句 (原本語言與 zh-TW 對照，各佔一行)\n" ..
                  "只回答，不要重覆提示\n\n" ..
                  "<<" .. highlightedText .. ">>",
            }
            table.insert(message_history, context_message)

            local answer = queryChatGPT(message_history)
            -- Save the answer to the message history
            local answer_message = {
              role = "assistant",
              content = answer,
            }

            table.insert(message_history, answer_message)
            UIManager:close(input_dialog)
            local result_text = 
              prev_context .. "<<" .. highlightedText .. ">>" .. next_context .. "\n\n" ..
              answer

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

            local chatgpt_viewer = ChatGPTViewer:new {
              title = _("AskGPT"),
              text = result_text,
              onAskQuestion = handleNewQuestion, -- Pass the callback function
            }

            UIManager:show(chatgpt_viewer)
end

return showChatGPTDialog
