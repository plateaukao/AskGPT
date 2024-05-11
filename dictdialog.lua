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
      "You are a dictionary with high quality vocabulary definitions and examples.",
    },
  }
  -- Add a loading message
  local InfoMessage = require("ui/widget/infomessage")
  local loading = InfoMessage:new {
    text = _("Loading..."),
    timeout = 1,
  }
  UIManager:show(loading)

  prev_context, next_context = ui.highlight:getSelectedWordContext(15)
            -- Give context to the question
            local context_message = {
              role = "user",
              content = 
                  prev_context .. "<<" .. highlightedText .. ">>" .. next_context .. "\n" ..
                  "explain vocabulary or content in <<>> in above sentence, in zh-TW with following format\n" .. 
                  "1. explanation\n" ..
                  "2. vocabulary original form. if it's Japanese, show its hiragana spelling\n" ..
                  "3. give an example in original language; and also attach zh-tw translation in second line\n" ..
                  "only show replies; no extra description nor information\n" ..
                  "----\n" ..
                  "here's an example\n" ..
                  "人の心は<<読める>>か？" ..
                  "and here's what to output:" ..
                  "1. 理解，讀取\n"..
                  "2. 読む(よむ)\n"..
                  "3. 日本語が読めます。\n"..
                  "   我能讀懂日文。\n",
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
