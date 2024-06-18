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
        "読めます → 読める（よめる）\n"..
        "指能夠理解或猜測他人的想法或情感。\n"..
        "例:彼の表情から彼女の気持ちが読める。\n"..
        "(從他的表情可以讀出她的心情。)\n\n"..
        "here's another example:\n" ..
        "I <<ate>> an apple." ..
        "and here's what to output:" ..
        "ate → eat\n"..
        "吃。指從嘴裡放進食物，咀嚼後進到肚子，以吸收營養。\n"..
        "例: I don't like eating fast food.\n"..
        "(我不愛吃速食。)\n"
  }
  
  return PROMPTS