# import uuid
# import base64
# import json
# import hashlib
# from Crypto.Cipher import AES
# from django.conf import settings
# BLOCK_SIZE = 16

# def pad(s: str) -> str:
#     pad_length = BLOCK_SIZE - len(s.encode('utf-8')) % BLOCK_SIZE
#     return s + chr(pad_length) * pad_length
# def unpad(s: str) -> str:
#     pad_len = ord(s[-1])
#     return s[:pad_len]
# def get_key():
#     return hashlib.md5(settings.AES_SECRET_KEY).digest()
# def encrypt_invite(data: dict) -> str:
#     raw = pad(json.dumps(data))
#     key =  hashlib.md5(settings.AES_SECRET_KEY).digest()
#     cipher = AES.new(key, AES.MODE_ECB)
#     encrypted = cipher.encrypt(raw.encode('utf-8'))
#     return base64.b64encode(encrypted).decode('utf-8')
# def decrypt_invite(encrypted_data: str) -> str:
#     key = get_key()
#     cipher = AES.new(key, AES.MODE_ECB)
#     decoded = base64.b64decode(encrypted_data)
#     decrypted = cipher.decrypt(decoded).decode('utf-8')
#     unpadded = unpad(decrypted)
#     return json.loads(unpadded)
import uuid
import base64
import json
import hashlib
from Crypto.Cipher import AES
from django.conf import settings

BLOCK_SIZE = 16

def pad(s: str) -> str:
    pad_length = BLOCK_SIZE - len(s.encode('utf-8')) % BLOCK_SIZE
    return s + chr(pad_length) * pad_length

def unpad(s: str) -> str:
    pad_len = ord(s[-1])
    return s[:-pad_len]  # ← 修正: s[:pad_len] ではなく、末尾から除去

def get_key() -> bytes:
    # すでに settings.AES_SECRET_KEY は bytes なので encode は不要
    key_source = settings.AES_SECRET_KEY
    if isinstance(key_source, str):
        key_source = key_source.encode("utf-8")
    return hashlib.md5(key_source).digest()

def encrypt_invite(data: dict) -> str:
    raw = pad(json.dumps(data))
    cipher = AES.new(get_key(), AES.MODE_ECB)
    encrypted = cipher.encrypt(raw.encode('utf-8'))
    return base64.b64encode(encrypted).decode('utf-8')

def decrypt_invite(encrypted_data: str) -> dict:
    cipher = AES.new(get_key(), AES.MODE_ECB)
    decoded = base64.b64decode(encrypted_data)
    decrypted = cipher.decrypt(decoded).decode('utf-8')
    unpadded = unpad(decrypted)
    return json.loads(unpadded)
