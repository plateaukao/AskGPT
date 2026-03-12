local InputDialog = require("ui/widget/inputdialog")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local _ = require("gettext")
local json = require("json")

local AskGPTConfig = require("config")

local function showMessage(text)
  UIManager:show(InfoMessage:new {
    text = text,
    timeout = 2,
  })
end

local function showConfigDialog(onSaved)
  local current = AskGPTConfig.load()
  local hint = _("Edit AskGPT config JSON. Use extra_buttons with id/text/provider/prompt. Use {{highlight}} in prompts.")

  local input_dialog
  input_dialog = InputDialog:new {
    title = _("AskGPT Config"),
    input = json.encode(current),
    input_hint = hint,
    buttons = {
      {
        {
          text = _("Template"),
          callback = function()
            input_dialog:setInputText(AskGPTConfig.template())
          end,
        },
        {
          text = _("Cancel"),
          callback = function()
            UIManager:close(input_dialog)
          end,
        },
        {
          text = _("Save"),
          callback = function()
            local raw = input_dialog:getInputText()
            local ok, parsed = pcall(json.decode, raw)
            if not ok or type(parsed) ~= "table" then
              showMessage(_("Invalid JSON. Config not saved."))
              return
            end
            local success, err = AskGPTConfig.save(parsed)
            if not success then
              showMessage(_("Failed to save config: ") .. tostring(err))
              return
            end
            showMessage(_("AskGPT config saved."))
            UIManager:close(input_dialog)
            if onSaved then
              onSaved()
            end
          end,
        },
      },
    },
  }

  UIManager:show(input_dialog)
  input_dialog:onShowKeyboard()
end

return showConfigDialog
