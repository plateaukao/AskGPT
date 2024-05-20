local InputDialog = require("ui/widget/inputdialog")
local ChatGPTViewer = require("chatgptviewer")
local UIManager = require("ui/uimanager")
local TextBoxWidget = require("ui/widget/textboxwidget")
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
      "You are a dictionary with high quality detail vocabulary definitions and examples.",
    },
  }
  prev_context, next_context = ui.highlight:getSelectedWordContext(10)
            -- Give context to the question
            local context_message = {
              role = "user",
              content = 
                  prev_context .. "<<" .. highlightedText .. ">>" .. next_context .. "\n" ..
                  "explain vocabulary or content in <<>> in above sentence, in zh-TW with following format\n" .. 
                  "1.vocabulary original form. if it's Japanese, show its hiragana spelling; if it's other languages, show original spelling. for example: went -> go; ran -> run\n" ..
                  "2.explanation of content in <<>> according to context\n" ..
                  "3.give an example in original language; and also attach zh-tw translation in second line\n" ..
                  "only show replies; no extra description nor information\n" ..
                  "----\n" ..
                  "here's an example\n" ..
                  "人の心は<<読める>>か？" ..
                  "and here's what to output:" ..
                  "読める（よめる）\n"..
                  "指能夠理解或猜測他人的想法或情感。\n"..
                  "例:彼の表情から彼女の気持ちが読める。\n"..
                  "(從他的表情可以讀出她的心情。)\n",
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
              TextBoxWidget.PTF_HEADER .. 
              prev_context .. TextBoxWidget.PTF_BOLD_START .. highlightedText .. TextBoxWidget.PTF_BOLD_END .. next_context .. "\n\n" ..
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
              title = _("GPT Dictionary"),
              text = result_text,
              onAskQuestion = handleNewQuestion, -- Pass the callback function
            }

            UIManager:show(chatgpt_viewer)
end

return showChatGPTDialog
