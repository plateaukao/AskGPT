local PROMPTS = {
  dict = "explain vocabulary or content in <<>> in above sentence, in zh-TW with following format\n" ..
      "1.vocabulary in original conjugation. if Japanese, show hiragana spelling; if s other languages, show original conjugation. for example: went -> go; ran -> run\n" ..
      "2.explanation of content in <<>> according to context\n" ..
      "3.give an example in original language; and also attach zh-tw translation in second line\n" ..
      "only show replies; no extra description nor information\n" ..
      "----\n" ..
      "here's an example\n" ..
      "人の心は<<読めます>>か？" ..
      "and here's what to output:" ..
      "読めます → 読める（よめる）\n" ..
      "指能夠理解或猜測他人的想法或情感。\n" ..
      "例:彼の表情から彼女の気持ちが読める。\n" ..
      "(從他的表情可以讀出她的心情。)\n\n" ..
      "here's another example:\n" ..
      "I <<ate>> an apple." ..
      "and here's what to output:" ..
      "ate → eat\n" ..
      "吃。指從嘴裡放進食物，咀嚼後進到肚子，以吸收營養。\n" ..
      "例: I don't like eating fast food.\n" ..
      "(我不愛吃速食。)\n",
  chapter_summary = table.concat({
    "你是一位深度閱讀顧問，專長是以繁體中文統整章節內容。",
    "請依照下列格式輸出：",
    "## 概要",
    "- 兩句話交代章節走向與氛圍。",
    "## 重點",
    "1. 條列核心事件或論點，共三項，每項不超過兩句。",
    "2. 針對人物衝突或重要資訊進行說明。",
    "3. 描述情緒或氛圍上的轉折。",
    "## 角色與主題",
    "- 角色：描述主要角色在本章的抉擇或情緒（1句）。",
    "- 主題／意涵：說明章節揭示的主題與情緒張力（1句）。",
    "## 延伸思考",
    "- 提出一個值得讀者反思的問題。",
    "避免原文逐句翻譯；如需引用原句，限制在 15 個字以內並加上引號。",
  }, "\n"),
}

return PROMPTS
