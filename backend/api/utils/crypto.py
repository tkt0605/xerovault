import uuid
import base64
import json
import hashlib
from Crypto.Cipher import AES
from django.conf import settings
from config.settings import AES_SECRET_KEY
BLOCK_SIZE = 16

def pad(s):
    return s + BLOCK_SIZE - len(s.encode('utf-8')) % BLOCK_SIZE * chr(BLOCK_SIZE - len(s.encode('utf-8')) % BLOCK_SIZE)
def encrypt_invite(data: dict) -> str:
    raw = pad(json.dumps(data))
    key =  hashlib.md5(AES_SECRET_KEY).digest()
    cipher = AES.new(key, AES.MODE_ECB)
    encrypted = cipher.encrypt(raw.encode('utf-8'))
    return base64.b64encode(encrypted).encode('utf-8')

