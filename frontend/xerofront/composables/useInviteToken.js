import CryptoJS from 'crypto-js';
const secretKey = 'bWGJPRCeMAFUjLrEIlgIUzbs9kwD/n4G';

const createEncryptedInvite = (token: String, expireAt: Number) => {
    const payload = JSON.stringify({token, exp: expireAt});
    const encrypted = CryptoJS.AES.encrypt(payload, secretKey).toString
}

