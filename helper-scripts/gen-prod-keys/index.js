'use strict';

const fs = require('fs');
const path = require('path');
const Keythereum = require('keythereum');
const EthereumTx = require('ethereumjs-tx');
const Web3 = require('web3');
const GeneratePassword = require('password-generator');
const mkdirp = require('mkdirp');

const RPC_ENDPOINT = process.env.RPC_ENDPOINT || 'http://localhost:8545';
const web3 = new Web3(new Web3.providers.HttpProvider(RPC_ENDPOINT));
const keysDir = '.';
const keysManagerAddress = process.argv[2];
const keysManagerABI = require('./KeysManager.abi.json');
var keysManagerContract;
var chainId;

const GASPRICE_GWEI = 2;

function loginf(...args) {
    console.log(new Date().toISOString(), ...args);
    fs.appendFileSync('./gen-prod-keys.out', new Date().toISOString() + ' ' + args.map(a => JSON.stringify(a)).join(' ') + '\n', 'utf8');
}

function logerr(...args) {
    console.error(new Date().toISOString(), ...args);
    fs.appendFileSync('./gen-prod-keys.err', new Date().toISOString() + ' ' + args.map(a => JSON.stringify(a)).join(' ') + '\n', 'utf8');
}

function generateKey(name) {
    var params = {
        keyBytes: 32,
        ivBytes: 16,
    };
    var dk = Keythereum.create(params);
    var password = GeneratePassword(20, false);
    var keyObj = Keythereum.dump(password, dk.privateKey, dk.salt, dk.iv, {});
    return {
        name,
        dk,
        password,
        keyObj,
    };
}

function validateArgs() {
    if (process.argv.length !== 3) {
        logerr('Usage: node index.js KEYS_MANAGER_ADDRESS');
        process.exit(1);
    }

    if (!web3.utils.isAddress(keysManagerAddress)) {
        logerr('Incorrect parameter KEYS_MANAGER_ADDRESS: ' + keysManagerAddress);
        logerr('Expecting 0x-prefixed address. If it contains both uppercase and lowercase letters, checksum is also validated.');
        process.exit(1);
    }
}

function getInitialKey(address) {
    var keyObj = Keythereum.importFromFile(address, keysDir);
    var password = fs.readFileSync(path.join(keysDir, './keystore', `${address}.key`), 'utf8');
    return {
        name: 'initial',
        keyObj,
        password
    };
}

function getPrivateKey(key) {
    return Keythereum.recover(key.password, key.keyObj);
}

function checkInitialKey(address, next) {
    keysManagerContract.methods.getInitialKey(`0x${address}`).call((err, result) => {
        if (err) throw err;
        return next(result.toString());
    });
}

function createKeys(address, privateKey, miningKeyAddress, votingKeyAddress, payoutKeyAddress, callback) {
    loginf('*** createKeys for: ' + address);
    loginf('calling estimateGas');
    keysManagerContract.methods.createKeys(`0x${miningKeyAddress}`, `0x${votingKeyAddress}`, `0x${payoutKeyAddress}`).estimateGas({ from: `0x${address}` }, (err, gasEstimation) => {
        if (err) throw err;

        loginf('gasEstimation:', gasEstimation);
        loginf('calling getTransactionCount');
        web3.eth.getTransactionCount(address, (err, nonce) => {
            if (err) throw err;

            loginf('nonce:', nonce);
            loginf('encoding method call');
            var txData = keysManagerContract.methods.createKeys(miningKeyAddress, votingKeyAddress, payoutKeyAddress).encodeABI();
            loginf('txData:', txData);
            var txParams = {
                from: `0x${address}`,
                to: keysManagerAddress,
                data: txData,
                gasPrice: web3.utils.toHex(web3.utils.toWei(GASPRICE_GWEI.toString(), 'gwei')),
                gasLimit: parseInt(gasEstimation),
                chainId: chainId,
                nonce: parseInt(nonce),
            };
            loginf('txParams:', txParams);

            loginf('signing tx');
            var tx = new EthereumTx(txParams);
            tx.sign(privateKey);
            var serializedTx = tx.serialize();
            loginf('calling sendSignedTransaction');

            web3.eth.sendSignedTransaction('0x' + serializedTx.toString('hex'))
            .on('transactionHash', txHash => loginf('got txHash:', txHash))
            .on('receipt', txReceipt => { loginf('got txReceipt:', txReceipt); callback(null, txReceipt); })
            .on('error', err => callback(err));
        });
        // setTimeout(callback, 5000);
    });
}

function asyncForEach(array, forEach, done) {
    if (array.length === 0) return done();

    var i = -1;
    function next(err) {
        if (err) return done(err);
        if (i === array.length - 1) return done();
        i += 1;
        setTimeout(function () { forEach(array[i], next) }, 11000);
    }
    next();
}

function saveKey(folder, key) {
    loginf(`* saving ${key.name} key:`, key.keyObj.address);
    loginf('* password:', key.password);
    loginf('* json keystore:', JSON.stringify(key.keyObj));
    fs.writeFileSync(`${folder}/${key.name}_${key.keyObj.address}.json`, JSON.stringify(key.keyObj));
    fs.writeFileSync(`${folder}/${key.name}_${key.keyObj.address}.key`, key.password);
}

function processInitialKeyFile(fname, done) {
    loginf('***** processing:', fname);
    var address = path.parse(fname).name;
    loginf('address:', address);
    if (!web3.utils.isAddress(`0x${address}`)) {
        logerr('Unexpected json keystore file name: ' + fname);
        process.exit(1);
    }
    var initialKey = getInitialKey(address, keysDir);
    var privateKey = getPrivateKey(initialKey);
    loginf('Recovered private key from initial key:', privateKey.toString('hex'));

    checkInitialKey(address, (r) => {
        // deactivated
        if (r == '2') {
            loginf('This initial key is deactivated, skipping');
            return done();
        }
        else if (r == '1') {
            loginf('This initial key is active, converting it to production keys...');
            var miningKey = generateKey('mining');
            var votingKey = generateKey('voting');
            var payoutKey = generateKey('payout');
            loginf('miningKey:', miningKey);
            loginf('votingKey:', votingKey);
            loginf('payoutKey:', payoutKey);
            createKeys(
                address,
                privateKey,
                miningKey.keyObj.address,
                votingKey.keyObj.address,
                payoutKey.keyObj.address,
                (err, txReceipt) => {
                    if (err) throw err;

                    var folder = `./production-keys/validator-${address}/`;
                    loginf('Creating keys folder:', folder);
                    mkdirp(folder);

                    saveKey(folder, initialKey);
                    saveKey(folder, miningKey);
                    saveKey(folder, votingKey);
                    saveKey(folder, payoutKey);

                    loginf('***** done with', fname);
                    return done();
                }
            );
        }
        else {
            logerr('This initial key is incorrect');
            throw new Error('Incorrect initial key');
        }
    });
}

// ********** MAIN ********* //
validateArgs();
keysManagerContract = new web3.eth.Contract(keysManagerABI, keysManagerAddress);

loginf('calling getId');
web3.eth.net.getId((err, _chainId) => {
    if (err) throw err;
    chainId = _chainId;
    var allKeys = fs.readdirSync(path.join(keysDir, './keystore')).filter(fname => !fname.startsWith('.') && !fname.startsWith('_') & fname.endsWith('.json'));
    loginf('allKeys:', allKeys);
    asyncForEach(allKeys, processInitialKeyFile, () => loginf('Completed'));
});
