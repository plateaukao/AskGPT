local Device = require("device")
local InputContainer = require("ui/widget/container/inputcontainer")
local _ = require("gettext")

local showChatGPTDialog = require("askdialog")
local showDictionaryDialog = require("dictdialog")

local AskGPT = InputContainer:new {
  name = "askgpt",
  is_doc_only = true,
}

function AskGPT:init()
  self.ui.highlight:addToHighlightDialog("askgpt_ChatGPT", function(_reader_highlight_instance)
    return {
      text = _("Ask ChatGPT"),
      enabled = Device:hasClipboard(),
      callback = function()
        prev_context, next_context = _reader_highlight_instance:getSelectedWordContext(15)
        showChatGPTDialog(self.ui, _reader_highlight_instance.selected_text.text)
        _reader_highlight_instance:onClose()
      end,
    }
  end)
  self.ui.highlight:addToHighlightDialog("askgpt_Dict", function(_reader_highlight_instance)
    return {
      text = _("ChatGPT Dictionary"),
      enabled = Device:hasClipboard(),
      callback = function()
        showDictionaryDialog(self.ui, _reader_highlight_instance.selected_text.text)
        _reader_highlight_instance:onClose()
      end,
    }
  end)
end

return AskGPT
