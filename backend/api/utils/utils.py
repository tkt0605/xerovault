import os, re
from urllib.parse import unquote

_SUFFIX_RE = re.compile(r'_[A-Za-z0-9]{6,10}$')  # 例: _chd7wJt, _a1B2c3d など

def pretty_filename(stored_name: str) -> str:
    base = os.path.basename(stored_name)
    base = unquote(base)  # 日本語をデコード
    stem, ext = os.path.splitext(base)
    # django-storages の重複回避サフィックスを除去
    stem = _SUFFIX_RE.sub('', stem)
    # Windows/Mac の複製名 "(1)" も念のため除去
    stem = re.sub(r'\s*\(\d+\)$', '', stem)
    return f"{stem}{ext}"