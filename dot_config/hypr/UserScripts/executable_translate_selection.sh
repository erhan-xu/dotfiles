#!/bin/bash

# 1. 获取选中文本并去除首尾空格
text=$(wl-paste --primary | xargs)

# 如果剪贴板为空，直接退出
if [ -z "$text" ]; then
  exit 1
fi

# 2. 预设变量
translation=""

# 3. 逻辑判断
char_count=$(echo -n "$text" | wc -m)

if [ "$char_count" -le 20 ]; then
  # === 离线查询模式 ===
  sdcv_result=$(sdcv -n "$text")

  if [[ "$sdcv_result" == *"Nothing similar to"* ]] || [[ -z "$sdcv_result" ]]; then
    # 查词失败 -> 转在线 (加 -no-ansi 防止颜色乱码)
    translation=$(trans -e bing -b -no-ansi :zh "$text")
  else
    # 查词成功 -> 清洗数据
    # sed '1d': 删除第一行 "Found 1 items..."
    # sed 's/^-->//': 删除行首的 "-->" 箭头 (这是报错的元凶)
    translation=$(echo "$sdcv_result" | sed '1d' | sed 's/^-->//' | head -n 20)
  fi
else
  # === 在线长句模式 ===
  translation=$(trans -e bing -b -no-ansi :zh "$text")
fi

# 防止空结果
if [ -z "$translation" ]; then
  translation="..."
fi

# 4. 发送通知 (核心修复)
# 注意中间那个孤立的双横线 --
# 它的作用是告诉 notify-send："停止解析选项，后面全是文本"
notify-send -u normal -a "Smart Translator" -- "原文: $text" "$translation"
