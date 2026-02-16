local ChatGPTViewer = require("chatgptviewer")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local Event = require("ui/event")
local T = require("ffi/util").template
local _ = require("gettext")

local PROMPTS = require("prompts")
local queryChatGPT = require("gpt_query")

local MAX_CHAPTER_CHARS = 12000

local function showError(text)
  UIManager:show(InfoMessage:new {
    text = text,
    timeout = 2,
  })
end

local function getAnchorFromHighlight(ui, highlight_instance)
  if not highlight_instance or not highlight_instance.selected_text then
    return ui.rolling and ui.document:getXPointer() or ui:getCurrentPage()
  end

  local pos0 = highlight_instance.selected_text.pos0
  if not pos0 then
    return ui.rolling and ui.document:getXPointer() or ui:getCurrentPage()
  end

  if type(pos0) == "string" then
    return pos0
  end

  return pos0.page or (ui.rolling and ui.document:getXPointer() or ui:getCurrentPage())
end

local function getChapterBounds(ui, anchor)
  local toc = ui.toc
  local chapter_index = toc:getTocIndexByPage(anchor, toc.toc_chapter_title_bind_to_ticks)
  if not chapter_index or not toc.toc or not toc.toc[chapter_index] then
    return nil, _("No chapter information available.")
  end

  local current_entry = toc.toc[chapter_index]
  local next_entry = toc.toc[chapter_index + 1]

  local start_xpointer = current_entry.xpointer
  local end_xpointer = next_entry and next_entry.xpointer or nil

  if not start_xpointer and ui.document.getPageXPointer and current_entry.page then
    start_xpointer = ui.document:getPageXPointer(current_entry.page)
  end

  if (not end_xpointer) and next_entry and next_entry.page and ui.document.getPageXPointer then
    end_xpointer = ui.document:getPageXPointer(next_entry.page)
  end

  if not end_xpointer and ui.document.getPageCount then
    local doc_pages = ui.document:getPageCount()
    if doc_pages then
      end_xpointer = ui.document:getPageXPointer(doc_pages + 1)
        or ui.document:getPageXPointer(doc_pages)
    end
  end

  if not start_xpointer or not end_xpointer then
    return nil, _("Unable to extract chapter text in this document format.")
  end

  local chapter_text = ui.document:getTextFromXPointers(start_xpointer, end_xpointer)
  if not chapter_text or chapter_text == "" then
    return nil, _("Chapter text is empty.")
  end

  local clean_title = toc:cleanUpTocTitle(current_entry.title, true)
  local page_start = current_entry.page or ui:getCurrentPage()
  local page_end_inclusive
  if next_entry and next_entry.page then
    page_end_inclusive = math.max(next_entry.page - 1, page_start)
  else
    local doc_pages = ui.document:getPageCount()
    page_end_inclusive = doc_pages and doc_pages or page_start
  end

  return {
    title = clean_title ~= "" and clean_title or _("Untitled chapter"),
    text = chapter_text,
    page_start = page_start,
    page_end = page_end_inclusive,
  }
end

local function clampChapterText(text)
  if not text then
    return nil, false
  end
  if #text <= MAX_CHAPTER_CHARS then
    return text, false
  end
  return text:sub(1, MAX_CHAPTER_CHARS), true
end

local function buildMetadataText(meta, truncated, chapter_len)
  local header = {}
  table.insert(header, T(_("Chapter: %1"), meta.title))
  table.insert(header, T(_("Pages: %1-%2"), meta.page_start, meta.page_end))
  table.insert(header, T(_("Captured characters: %1%2"),
    chapter_len,
    truncated and _(" (truncated)") or ""))
  return table.concat(header, "\n")
end

local function buildResultText(metadata_block, message_history)
  local parts = { metadata_block, "" }
  for i = 3, #message_history do
    local entry = message_history[i]
    if entry.role == "user" then
      table.insert(parts, _("User: ") .. entry.content)
    else
      table.insert(parts, entry.content)
    end
    table.insert(parts, "")
  end
  return table.concat(parts, "\n")
end

local function showSummaryDialog(ui, highlight_instance)
  local anchor = getAnchorFromHighlight(ui, highlight_instance)
  local chapter_meta, err = getChapterBounds(ui, anchor)
  if not chapter_meta then
    showError(err)
    return
  end

  local chapter_text, truncated = clampChapterText(chapter_meta.text)
  if not chapter_text or chapter_text == "" then
    showError(_("Failed to capture chapter text."))
    return
  end

  local title = ui.document:getProps().title or _("Unknown Title")
  local author = ui.document:getProps().authors or _("Unknown Author")
  local metadata_block = buildMetadataText(chapter_meta, truncated, #chapter_text)

  local chapter_payload = string.format(
    "Book: %s\nAuthor: %s\nChapter: %s\nPage range: %s-%s\n\nChapter text:\n%s",
    title,
    author,
    chapter_meta.title,
    chapter_meta.page_start,
    chapter_meta.page_end,
    chapter_text
  )

  local message_history = {
    {
      role = "system",
      content = PROMPTS.chapter_summary,
    },
    {
      role = "user",
      content = chapter_payload,
    },
  }

  local ok, summary = pcall(queryChatGPT, message_history)
  if not ok then
    showError(_("Failed to fetch summary."))
    return
  end

  table.insert(message_history, { role = "assistant", content = summary })
  local result_text = buildResultText(metadata_block, message_history)

  local chatgpt_viewer

  local function handleAddToNote()
    local index = ui.highlight:saveHighlight(true)
    local annotation = ui.annotation.annotations[index]
    annotation.note = result_text
    ui:handleEvent(Event:new("AnnotationsModified",
      { annotation, nb_highlights_added = -1, nb_notes_added = 1 }))

    UIManager:close(chatgpt_viewer)
    ui.highlight:onClose()
  end

  local function handleNewQuestion(viewer, question)
    table.insert(message_history, { role = "user", content = question })
    local ok_answer, answer = pcall(queryChatGPT, message_history)
    if not ok_answer then
      table.remove(message_history)
      showError(_("Failed to fetch summary."))
      return
    end
    table.insert(message_history, { role = "assistant", content = answer })
    result_text = buildResultText(metadata_block, message_history)
    viewer:update(result_text)
  end

  chatgpt_viewer = ChatGPTViewer:new {
    ui = ui,
    title = _("Chapter Summary"),
    text = result_text,
    onAskQuestion = handleNewQuestion,
    onAddToNote = handleAddToNote,
  }

  UIManager:show(chatgpt_viewer)
end

return showSummaryDialog
