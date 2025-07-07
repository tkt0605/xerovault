import base64
import json
import hashlib
from Crypto.Cipher import AES
from Crypto.Random import get_random_bytes
from django.conf import settings

BLOCK_SIZE = 16

def pad(s: str) -> bytes:
    bs = BLOCK_SIZE
    s_bytes = s.encode('utf-8')
    pad_len = bs - len(s_bytes) % bs
    return s_bytes + bytes([pad_len] * pad_len)

def unpad(s: bytes) -> str:
    pad_len = s[-1]
    return s[:-pad_len].decode('utf-8')

def get_key() -> bytes:
    key_source = settings.AES_SECRET_KEY
    if isinstance(key_source, str):
        key_source = key_source.encode("utf-8")
    return hashlib.md5(key_source).digest()  # 16バイトキー

def encrypt_invite(data: dict) -> str:
    key = get_key()
    iv = get_random_bytes(16)
    raw = pad(json.dumps(data))
    cipher = AES.new(key, AES.MODE_CBC, iv)
    encrypted = cipher.encrypt(raw)
    return base64.b64encode(iv + encrypted).decode('utf-8')

def decrypt_invite(encrypted_data: str) -> dict:
    raw = base64.b64decode(encrypted_data)
    iv = raw[:16]
    encrypted = raw[16:]
    key = get_key()
    cipher = AES.new(key, AES.MODE_CBC, iv)
    decrypted = cipher.decrypt(encrypted)
    return json.loads(unpad(decrypted))

