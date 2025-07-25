from urllib.parse import unquote_plus
import base64
import json
import hashlib
from Crypto.Cipher import AES
from Crypto.Random import get_random_bytes
from django.conf import settings
import logging

logger = logging.getLogger(__name__)
BLOCK_SIZE = 16

def pad(s: str) -> bytes:
    s_bytes = s.encode('utf-8')
    pad_len = BLOCK_SIZE - len(s_bytes) % BLOCK_SIZE
    return s_bytes + bytes([pad_len] * pad_len)

def unpad(s: bytes) -> str:
    pad_len = s[-1]
    return s[:-pad_len].decode('utf-8')

def get_key() -> bytes:
    key_source = settings.AES_SECRET_KEY
    if isinstance(key_source, str):
        key_source = key_source.encode("utf-8")
    return hashlib.md5(key_source).digest()

def fix_base64_padding(s: str) -> str:
    s = s.strip().replace(" ", "").replace("\n", "")
    missing_padding = len(s) % 4
    if missing_padding:
        s += '=' * (4 - missing_padding)
    return s

def encrypt_invite(data: dict) -> str:
    key = get_key()
    iv = get_random_bytes(16)
    raw = pad(json.dumps(data))
    cipher = AES.new(key, AES.MODE_CBC, iv)
    encrypted = cipher.encrypt(raw)
    token = base64.urlsafe_b64encode(iv + encrypted).decode('utf-8').rstrip('=')
    return token

def decrypt_invite(encrypted_data: str) -> dict:
    try:
        logger.info(f"[DEBUG] Raw encrypted_data: {encrypted_data}")
        decoded = unquote_plus(encrypted_data)
        logger.info(f"[DEBUG] After unquote_plus: {repr(decoded)} (len={len(decoded)})")

        padded = fix_base64_padding(decoded)
        logger.info(f"[DEBUG] After fix_base64_padding: {repr(padded)} (len={len(padded)})")

        raw = base64.urlsafe_b64decode(padded)
        logger.info(f"[DEBUG] base64 decoded length: {len(raw)}")

        if len(raw) < 17:
            raise ValueError('デコードされたデータが短すぎます。')

        iv = raw[:16]
        encrypted = raw[16:]

        logger.info(f"[DEBUG] IV: {iv.hex()} | Encrypted length: {len(encrypted)}")

        if len(encrypted) % 16 != 0:
            raise ValueError(f"暗号文の長さ {len(encrypted)} が16バイトの倍数ではありません。")

        key = get_key()
        cipher = AES.new(key, AES.MODE_CBC, iv)
        decrypted = cipher.decrypt(encrypted)
        return json.loads(unpad(decrypted))

    except Exception as e:
        logger.error(f"[decrypt_invite] デコードエラー: {str(e)}")
        raise ValueError(f"[decrypt_invite] デコードエラー: {str(e)}")
