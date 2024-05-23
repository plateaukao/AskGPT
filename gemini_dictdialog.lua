local InputDialog = require("ui/widget/inputdialog")
local ChatGPTViewer = require("chatgptviewer")
local UIManager = require("ui/uimanager")
local TextBoxWidget = require("ui/widget/textboxwidget")
local _ = require("gettext")

local queryGemini = require("gemini_query")

local function showGeminiDictDialog(ui, highlightedText, message_history)
  prev_context, next_context = ui.highlight:getSelectedWordContext(10)

  local context_message = prev_context .. "<<" .. highlightedText .. ">>" .. next_context .. "\n" ..
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
        "(從他的表情可以讀出她的心情。)\n\n"..
        "here's another example:\n" ..
        "I <<ate>> an apple." ..
        "and here's what to output:" ..
        "eat\n"..
        "吃。指從嘴裡放進食物，咀嚼後進到肚子，以吸收營養。\n"..
        "例: I don't like eating fast food.\n"..
        "(我不愛吃速食。)\n"

  local answer = queryGemini(context_message)

  local result_text = 
    TextBoxWidget.PTF_HEADER .. 
    prev_context .. TextBoxWidget.PTF_BOLD_START .. highlightedText .. TextBoxWidget.PTF_BOLD_END .. next_context .. "\n\n" ..
    answer

  local function handleNewQuestion(chatgpt_viewer, question)
  end

  local chatgpt_viewer = nil

  local function handleAddToNote()
    ui.highlight:addNote(answer)
    UIManager:close(chatgpt_viewer)
    ui.highlight:onClose()
  end

  chatgpt_viewer = ChatGPTViewer:new {
    ui = ui,
    title = _("Gemini Dictionary"),
    text = result_text,
    onAskQuestion = handleNewQuestion, -- Pass the callback function
    onAddToNote = handleAddToNote,
  }

  UIManager:show(chatgpt_viewer)
end

return showGeminiDictDialog
