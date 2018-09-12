var keythereum = require('keythereum');
var fs = require('fs');

const MOC_SECRET = process.env.MOC_SECRET;
const NETWORK_NAME = process.env.CERTPATH;

if (!MOC_SECRET || !NETWORK_NAME) throw new Error('MOC_SECRET and NETWORK_NAME env variables are required');

// optional private key and initialization vector sizes in bytes
// (if params is not passed to create, keythereum.constants is used by default)
var params = { keyBytes: 32, ivBytes: 16 };

// synchronous
var dk = keythereum.create(params);

var options = {
  kdf: "pbkdf2",
  cipher: "aes-128-ctr",
  kdfparams: {
    c: 262144,
    dklen: 32,
    prf: "hmac-sha256"
  }
};

var password = MOC_SECRET;

// synchronous
var keyObject = keythereum.dump(password, dk.privateKey, dk.salt, dk.iv, options);

fs.writeFileSync(`${NETWORK_NAME}/moc.json`, JSON.stringify(keyObject), 'utf8');
fs.writeFileSync(`${NETWORK_NAME}/moc`, `0x${keyObject.address}`, 'utf8');
