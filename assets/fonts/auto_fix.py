# coding: utf-8
import os
import re

def fix_mojibake(s: str) -> str:
    try:
        # Step 1: Try CP1252 encoding to get raw CP1252 bytes, then decode as UTF-8
        return s.encode('cp1252').decode('utf-8')
    except Exception:
        try:
            # Step 2: Fallback to ISO-8859-1 (Latin-1)
            return s.encode('latin1').decode('utf-8')
        except Exception:
            return s

# Regex to match string literals (both single and double quoted, supporting escape sequences)
str_double_re = re.compile(r'"([^"\\]*(?:\\.[^"\\]*)*)"')
str_single_re = re.compile(r"'([^'\\]*(?:\\.[^'\\]*)*)'")

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    # Replaces the string literal's inner content
    def replace_double(match):
        inner = match.group(1)
        fixed = fix_mojibake(inner)
        return f'"{fixed}"'

    def replace_single(match):
        inner = match.group(1)
        fixed = fix_mojibake(inner)
        return f"'{fixed}'"

    new_content = str_double_re.sub(replace_double, content)
    new_content = str_single_re.sub(replace_single, new_content)

    # Some manual adjustments for edge cases
    manual_replacements = {
        "Hoáº·c": "Hoặc",
        "tiáº¿p tá»¥c": "tiếp tục",
        "khÃ´ng": "không",
        "cáº§n": "cần",
        "tÃ\xa0i": "tài",
        "khoáº£n:": "khoản:",
        "ChÆ¡i": "Chơi",
        "Thá»\xad": "Thử",
        "t\xa0i": "tài",
        "Th\xad": "Thử",
        "Ã¢": "â",
        "Ãª": "ê",
        "Ã´": "ô",
        "Ã¹": "ù",
        "Ãº": "ú",
        "Ã½": "ý",
        "Ã³": "ó",
        "Ã ": "à",
        "Ã¡": "á",
        "Ã£": "ã",
        "Ã\xad": "í",
        "Ã\xa0": "à",
        "Ä\x83": "ă",
        "Ä‘": "đ",
        "Ä\x90": "Đ",
        "Æ°": "ư",
        "Æ¡": "ơ",
        "áº£": "ả",
        "áº§": "ầ",
        "áº¯": "ắ",
        "áº\xad": "ậ",
        "á»\x9f": "ở",
        "á»\x91": "ố",
        "á»\x8b": "ị",
        "á»\x8d": "ọ",
        "á»\x81": "ề",
        "á»\x83": "ể",
        "á»\x93": "ồ",
        "á»\x95": "ổ",
        "á»\x99": "ộ",
        "á»\x9b": "ớ",
        "á»\x9d": "ờ",
        "á»\xa0": "ợ",
        "á»\xa3": "ợ",
        "á»\xa5": "ụ",
        "á»\xa7": "ủ",
        "á»\xab": "ừ",
        "á»\xad": "ử",
        "á»\xb1": "ự",
        "áº½": "ẽ"
    }
    for key, val in manual_replacements.items():
        new_content = new_content.replace(key, val)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)

scripts_dir = "e:/VietStageGame/scripts/ui"
for root_path, dirs, files in os.walk(scripts_dir):
    for f in files:
        if f.endswith(".gd"):
            process_file(os.path.join(root_path, f))

print("Auto string fixes completed successfully!")
