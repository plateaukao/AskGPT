local Device = require("device")
local InputContainer = require("ui/widget/container/inputcontainer")
local UIManager = require("ui/uimanager")
local _ = require("gettext")

local showChatGPTDialog = require("askdialog")
local showDictionaryDialog = require("dictdialog")
local showTranslateDialog = require("translatedialog")

local showGeminiDictDialog = require("gemini_dictdialog")

local AskGPT = InputContainer:new {
  name = "askgpt",
  is_doc_only = true,
}

function showLoadingDialog()
  local InfoMessage = require("ui/widget/infomessage")
  local loading = InfoMessage:new {
    text = _("Loading..."),
    timeout = 0.1,
  }
  UIManager:show(loading)
end

function AskGPT:init()
  self.ui.highlight:addToHighlightDialog("askgpt_ChatGPT", function(_reader_highlight_instance)
    return {
      text = _("Ask ChatGPT"),
      enabled = Device:hasClipboard(),
      callback = function()
        showChatGPTDialog(self.ui, _reader_highlight_instance.selected_text.text)
      end,
    }
  end)
  self.ui.highlight:addToHighlightDialog("askgpt_Dict", function(_reader_highlight_instance)
    return {
      text = _("GPT Dictionary"),
      enabled = Device:hasClipboard(),
      callback = function()
        showLoadingDialog()
        UIManager:scheduleIn(0.1, function()
          showDictionaryDialog(self.ui, _reader_highlight_instance.selected_text.text)
        end)
      end,
    }
  end)
  self.ui.highlight:addToHighlightDialog("askgpt_gemini_dict", function(_reader_highlight_instance)
    return {
      text = _("Gemini Dictionary"),
      enabled = Device:hasClipboard(),
      callback = function()
        showLoadingDialog()
        UIManager:scheduleIn(0.1, function()
          showGeminiDictDialog(self.ui, _reader_highlight_instance.selected_text.text)
        end)
      end,
    }
  end)
  self.ui.highlight:addToHighlightDialog("askgpt_Translate", function(_reader_highlight_instance)
    return {
      text = _("GPT Translate"),
      enabled = Device:hasClipboard(),
      callback = function()
        showLoadingDialog()
        UIManager:scheduleIn(0.1, function()
          showTranslateDialog(self.ui, _reader_highlight_instance.selected_text.text)
        end)
      end,
    }
  end)
end

return AskGPT
