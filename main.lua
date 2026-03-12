local Device = require("device")
local InputContainer = require("ui/widget/container/inputcontainer")
local UIManager = require("ui/uimanager")
local _ = require("gettext")
local NetworkMgr = require("ui/network/manager")
local InfoMessage = require("ui/widget/infomessage")

local showChatGPTDialog = require("askdialog")
local showDictionaryDialog = require("dictdialog")
local showTranslateDialog = require("translatedialog")
local showSummaryDialog = require("summarydialog")
local showConfigDialog = require("configdialog")

local showGeminiDictDialog = require("gemini_dictdialog")
local showExtraPromptDialog = require("extra_prompt_dialog")
local AskGPTConfig = require("config")

local AskGPT = InputContainer:new {
  name = "askgpt",
  is_doc_only = true,
}

function showLoadingDialog(highlight_instance)
  if highlight_instance.highlight_dialog then
    UIManager:close(highlight_instance.highlight_dialog)
    highlight_instance.highlight_dialog = nil
  end

  local loading = InfoMessage:new {
    text = _("Loading..."),
    timeout = 0.1,
  }
  UIManager:show(loading)
end

function isStreamMode(provider)
  local config = AskGPTConfig.load()
  if provider == "gemini" then
    return config.gemini_stream
  end
  return config.openai_stream
end

function checkNetworkStatus()
  if not NetworkMgr:isConnected() then
    UIManager:show(InfoMessage:new {
      text = _("No internet connection"),
      timeout = 2,
    })
    return false
  end
  return true
end

function AskGPT:addExtraButtons()
  local config = AskGPTConfig.load()
  local extra_buttons = config.extra_buttons or {}

  for idx, button in ipairs(extra_buttons) do
    if type(button) == "table" and button.text and button.prompt then
      local button_id = "askgpt_extra_" .. tostring(button.id or idx)
      self.ui.highlight:addToHighlightDialog(button_id, function(_reader_highlight_instance)
        return {
          text = _(button.text),
          enabled = Device:hasClipboard(),
          callback = function()
            if not checkNetworkStatus() then
              return
            end
            if not isStreamMode(button.provider) then
              showLoadingDialog(_reader_highlight_instance)
            end
            UIManager:scheduleIn(0.1, function()
              showExtraPromptDialog(self.ui, _reader_highlight_instance.selected_text.text, button)
            end)
          end,
        }
      end)
    end
  end
end

function AskGPT:init()
  -- remove some that I don't use
  self.ui.highlight:removeFromHighlightDialog("04_add_note")
  self.ui.highlight:removeFromHighlightDialog("05_wikipedia")
  self.ui.highlight:removeFromHighlightDialog("08_share_text")
  self.ui.highlight:removeFromHighlightDialog("09_view_html")

  self.ui.highlight:addToHighlightDialog("askgpt_ChatGPT", function(_reader_highlight_instance)
    return {
      text = _("Ask ChatGPT"),
      enabled = Device:hasClipboard(),
      callback = function()
        if not checkNetworkStatus() then
          return
        end
        showChatGPTDialog(self.ui, _reader_highlight_instance.selected_text.text)
      end,
    }
  end)
  self.ui.highlight:addToHighlightDialog("askgpt_Dict", function(_reader_highlight_instance)
    return {
      text = _("GPT Dictionary"),
      enabled = Device:hasClipboard(),
      callback = function()
        if not checkNetworkStatus() then
          return
        end
        if not isStreamMode("openai") then
          showLoadingDialog(_reader_highlight_instance)
        end
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
        if not checkNetworkStatus() then
          return
        end
        if not isStreamMode("gemini") then
          showLoadingDialog(_reader_highlight_instance)
        end
        UIManager:scheduleIn(0.1, function()
          showGeminiDictDialog(self.ui, _reader_highlight_instance.selected_text.text)
        end)
      end,
    }
  end)
  self.ui.highlight:addToHighlightDialog("askgpt_summary", function(_reader_highlight_instance)
    return {
      text = _("Summarize Chapter"),
      enabled = true,
      callback = function()
        if not checkNetworkStatus() then
          return
        end
        if not isStreamMode("openai") then
          showLoadingDialog(_reader_highlight_instance)
        end
        UIManager:scheduleIn(0.1, function()
          showSummaryDialog(self.ui, _reader_highlight_instance)
        end)
      end,
    }
  end)
  self.ui.highlight:addToHighlightDialog("askgpt_Translate", function(_reader_highlight_instance)
    return {
      text = _("GPT Translate"),
      enabled = Device:hasClipboard(),
      callback = function()
        if not checkNetworkStatus() then
          return
        end
        if not isStreamMode("openai") then
          showLoadingDialog(_reader_highlight_instance)
        end
        UIManager:scheduleIn(0.1, function()
          showTranslateDialog(self.ui, _reader_highlight_instance.selected_text.text)
        end)
      end,
    }
  end)

  self.ui.highlight:addToHighlightDialog("askgpt_config", function(_reader_highlight_instance)
    return {
      text = _("AskGPT Config"),
      enabled = true,
      callback = function()
        showConfigDialog(function()
          UIManager:show(InfoMessage:new {
            text = _("Config saved. Reopen book to reload extra buttons."),
            timeout = 2,
          })
        end)
      end,
    }
  end)

  self:addExtraButtons()
end

return AskGPT
