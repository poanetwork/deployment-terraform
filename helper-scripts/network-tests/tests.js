const fs = require('fs');
const toml = require('toml');
const config = toml.parse(fs.readFileSync('./config.toml', 'utf-8'));
const Web3 = require("web3");
const web3 = new Web3(new Web3.providers.HttpProvider(config.url));
const EthereumTx = require('ethereumjs-tx');
const utils = require('web3-utils');
const winston = require('winston');

const abi = JSON.parse(fs.readFileSync(config.consensensusAbiPath));
const contractAddress = JSON.parse(fs.readFileSync(config.contractsAddressPath)).POA_ADDRESS;
const PoaNetworkConsensusContract = new web3.eth.Contract(abi, contractAddress);

let validatorsArr;
const accountFromPath = config.keyStorePath;
const accountToAddress = config.addressTo;
const accountFromPassword = config.passwordFrom;
let validatorsMinedTx = {};
//for saving validators who mined blocks with txs
let validatorsMinedTxSet = new Set();
let lastBlock;

let blocksChecked = 0;
let previousValidatorIndex = -1;
let previousValidator = "";
let previousBlockNumber = -1;
let startValidatorIndex = -1;
let validatorsLength = 0;
let currentValidatorIndex;

const logger = winston.createLogger({
    format: winston.format.printf(info => `${new Date().toLocaleString()} ${info.level}: ${info.message}`),
    exitOnError: false,
    transports: [
        new winston.transports.Console({
            level: 'debug'
        }),
        new winston.transports.File({
            filename: './error.log',
            level: 'error',
        }),
        new winston.transports.File({
            filename: './combined.log',
            level: 'debug',
        })
    ]
});

function errExit(msg) {
    logger.error(msg);
    setTimeout(() => { throw new Error(msg); }, 0);
}

testAll(config.maxRounds)
    .then(result => {
        logger.info("Checked ");
    })
    .catch(err => {
        errExit("Error2 in testAll(): " + err);
    });

async function testAll(maxRounds) {
    let decryptedAccount = getDecryptedAccount(accountFromPath, accountFromPassword);
    //will be saved as test result
    let validatorsMissedTxs = [];
    getValidators()
        .then(() => {
            return checkSeriesOfTransactions(decryptedAccount, maxRounds);
        })
        .then(async txsResult => {
            if (validatorsMinedTxSet.size !== validatorsArr.length) {
                txsResult.passed = false;
                //determine what validator's node didn't mine tx
                for (let i = 0; i < validatorsArr.length; i++) {
                    if (!validatorsMinedTxSet.has(validatorsArr[i])) {
                        validatorsMissedTxs.push(validatorsArr[i]);
                    }
                }
            }
            let message = '\r\n____________________\r\n Sending txs passed: ' + txsResult.passed + ', \n ValidatorsMissedTxs: '
                + JSON.stringify(validatorsMissedTxs) + ', \n FailedTxs: ' + JSON.stringify(txsResult.failedTxs) +
                ", \n Number of rounds with txs: " + txsResult.checkedRounds;
            if (txsResult.passed) {
                logger.info(message);
            } else {
                errExit("Sending txs failed: " + message);
            }

            // check for validators missed round. Wait some time for including empty blocks to the checks
            setTimeout(function () {
                logger.debug("call checkRound");
                checkRound().then(roundsResult => {
                    logger.debug("got roundsResult ");
                    let message = "\r\n_____________________\r\n RoundsResult: " + JSON.stringify(roundsResult);
                    if (roundsResult.passed) {
                        logger.info(message);
                    } else {
                        errExit("Test for missing rounds failed: " + message);
                    }
                }).catch(error => {
                    errExit("error in checkRound(): " + error);
                });
            }, config.timeoutSeconds * 1000);
        })
        .catch(error => {
            errExit("error in testAll(): " + error);
        });
}

/**
 * Sends series of transactions and checks if they all were mined and all validators mined at least one transaction.
 * Few rounds are needed in case of empty blocks were created too during sending txs.
 * @param decryptedAccount
 * @param maxRounds
 * @returns {Promise.<{passed: boolean, failedTxs: Array, checkedRounds: number}>}
 */
async function checkSeriesOfTransactions(decryptedAccount, maxRounds) {
    logger.debug("checkSeriesOfTransactions(), maxRounds: " + maxRounds);
    let result = {passed: true, failedTxs: [], checkedRounds: 0};
    for (let round = 0; round < maxRounds; round++) {
        logger.info("round: " + round);
        result.checkedRounds = round + 1;
        for (let i = 0; i < validatorsArr.length; i++) {
            logger.info("send " + i + "th transaction in the round");
            await sendRawTx(decryptedAccount, accountToAddress, config.amountToSend, config.simpleTransactionGas, config.gasPrice)
                .then(async txReceipt => {
                    logger.info("txReceipt: " + JSON.stringify(txReceipt));
                    return checkTxReceipt(txReceipt);
                }).then(async transactionResult => {
                    if (!transactionResult.passed) {
                        result.passed = false;
                        errExit("Transaction failed, error: " + transactionResult.errorMessage);
                    }
                }).catch(error => {
                    errExit("Error in checkSeriesOfTransactions(): " + error);
                })
        }
        logger.info("validatorsSet size: " + validatorsMinedTxSet.size);
        logger.info("validatorsMinedTx: " + JSON.stringify(validatorsMinedTx));
        if (validatorsMinedTxSet.size === validatorsArr.length) {
            //all validators mined blocks with txs so no need to continue test
            break;
        }
    }
    return result;
}

/**
 * Gets blocks from the latest round and checks if any validator missed round
 * @returns {Promise.<{passed: boolean, missedValidators: Array}>}
 */
async function checkRound() {
    logger.debug("checkRound()");
    let roundsResult = {passed: true, missedValidators: []};
    let blocks = await getBlocksFromLatestRound(validatorsArr.length);
    for (let block of blocks) {
        logger.debug("block: " + JSON.stringify(block));
        let missedFromBlock = await checkBlock(block);
        logger.info("missedFromBlock: " + JSON.stringify(missedFromBlock));
        if (missedFromBlock) {
            for (let validator of missedFromBlock) {
                if (roundsResult.missedValidators.indexOf(validator) === -1) {
                    roundsResult.missedValidators.push(validator);
                    roundsResult.passed = false;
                    logger.error("received missedValidator: " + validator);
                }
            }
        }
    }
    return roundsResult;
}

/**
 *Checks validator of the block
 * @param blockHeader
 * @returns {Promise.<Array>} - validators who missed their turn
 */
async function checkBlock(blockHeader) {
    logger.info("checkBlock() Got new block: " + blockHeader.number + ", validator: " + blockHeader.miner +
        ", previousValidatorIndex: " + previousValidatorIndex + ", lastBlock: " + lastBlock);
    validatorsLength = validatorsArr.length;
    lastBlock = blockHeader.number;
    let blocksPassed = lastBlock - previousBlockNumber;
    if (blocksPassed !== 1) {
        logger.warn("didn't get expected block, blocksPassed: " + blocksPassed);
    }
    logger.info("blocksPassed: " + blocksPassed + ", lastBlock: " + lastBlock + ", previousBlockNumber: " + previousBlockNumber);
    blockHeader.miner = web3.utils.toChecksumAddress(blockHeader.miner);
    currentValidatorIndex = validatorsArr.indexOf(blockHeader.miner);
    let missedValidators = [];
    if (previousBlockNumber === -1  // in the begin of the test
    ) {
        startValidatorIndex = currentValidatorIndex;
        logger.info("begin, previousValidatorIndex: " + previousValidatorIndex);
    } else {
        let expectedValidatorIndex = (previousValidatorIndex + blocksPassed) % validatorsLength;
        let expectedValidator = validatorsArr[expectedValidatorIndex];
        let isPassed = expectedValidator === blockHeader.miner;
        logger.info("expectedValidatorIndex: " + expectedValidatorIndex + ", expectedValidator: " + expectedValidator + ", actual: " + blockHeader.miner + ", passed: " + isPassed);
        if (!isPassed) {
            let ind = expectedValidatorIndex;
            // more then one validator could miss round in one time
            // all validators in array from expected one till actual will be missed
            let added = 0;
            while (ind !== currentValidatorIndex && added < validatorsLength) {
                logger.error("add missed validator, index: " + ind + ", validator : " + validatorsArr[ind] + ", atBlock: " + lastBlock);
                missedValidators.push(validatorsArr[ind]);
                ind = (ind + 1) % validatorsLength;
                added++;
            }
        }
        logger.info("blocksChecked: " + blocksChecked);
    }
    blocksChecked++;
    previousValidator = blockHeader.miner;
    previousBlockNumber = lastBlock;
    previousValidatorIndex = currentValidatorIndex;
    return missedValidators;
}

async function checkTxReceipt(receipt) {
    logger.debug("checkTxReceipt()");
    let result = {passed: true, blockNumber: "", transactionHash: "", errorMessage: ""};
    logger.info("transactionHash: " + receipt.transactionHash);
    if (receipt.transactionHash === undefined || receipt.transactionHash === null || receipt.transactionHash.length === 0) {
        result.passed = false;
        result.errorMessage = "No transaction hash is the receipt ";
        logger.error("No transaction hash is the receipt, receipt.transactionHash: " + receipt.transactionHash);
    }
    if (receipt.blockNumber === undefined || receipt.blockNumber === null || receipt.blockNumber.length === 0) {
        result.passed = false;
        result.errorMessage = "No blockNumber is the receipt";
        logger.error("No blockNumber is the receipt, receipt.blockNumber: " + receipt.blockNumber)
    }
    result.transactionHash = receipt.transactionHash;
    result.blockNumber = receipt.blockNumber;
    logger.info("checkTxReceipt result: " + JSON.stringify(result));
    await checkWhoMinedTxs(receipt);
    return result;
}

async function sendRawTx(decryptedAccount, to, value, gas, gasPrice) {
    logger.debug("sendRawTx()");
    const privateKeyHex = Buffer.from(decryptedAccount.privateKey.replace('0x', ''), 'hex');
    const nonce = await web3.eth.getTransactionCount(decryptedAccount.address);
    logger.info("nonce: " + nonce);
    let rawTransaction = {
        "from": decryptedAccount.address,
        "to": to,
        "value": utils.toHex(value),
        "gas": utils.toHex(gas),
        "gasPrice": utils.toHex(gasPrice),
        "nonce": nonce
    };
    logger.info("rawTransaction: " + JSON.stringify(rawTransaction));
    let tx = new EthereumTx(rawTransaction);
    tx.sign(privateKeyHex);
    let serializedTx = '0x' + tx.serialize().toString('hex');
    return web3.eth.sendSignedTransaction(serializedTx);
}

/**
 * Determines validator who mined tx and saves to the validatorsMinedTxSet and validatorsMinedTx
 *
 * @param receipt
 * @returns {Promise.<void>}
 */
async function checkWhoMinedTxs(receipt) {
    logger.debug("checkWhoMinedTxs() ");
    lastBlock = receipt.blockNumber;
    const block = await web3.eth.getBlock(lastBlock);
    logger.info("blockNumber: " + lastBlock + ", validator: " + block.miner);
    if (!validatorsMinedTxSet.has(block.miner)) {
        validatorsMinedTxSet.add(block.miner);
        logger.info("add to validatorsMinedTxSet");
    }
    if (validatorsMinedTx[block.miner]) {
        validatorsMinedTx[block.miner] += 1;
        logger.info("validator mined txs " + validatorsMinedTx[block.miner] + " times");
    } else {
        validatorsMinedTx[block.miner] = 1;
        logger.info("validator mined tx for the first time ");
    }
}

/**
 * Returns the array of latest blocks. Array length will be equal to the number of validators to fit the round.
 *
 * @param numberOfValidators
 * @returns {Array}
 */
async function getBlocksFromLatestRound(numberOfValidators) {
    logger.debug("getBlocksFromLatestRound(), numberOfValidators: " + numberOfValidators);
    const lastBlock = await web3.eth.getBlock('latest');
    const firstNum = lastBlock.number - numberOfValidators + 1;
    let blocks = [];
    for (let i = 0; i < numberOfValidators; i++) {
        blocks[i] = await web3.eth.getBlock(firstNum + i);
        logger.info(i + "th: number: " + blocks[i].number + ", validator: " + blocks[i].miner);
    }
    logger.info("blocks.length: " + blocks.length);
    return blocks;
}

function getKeystore(path) {
    logger.debug("getKeystore()");
    let keyStore;
    try {
        keyStore = fs.readFileSync(path);
    } catch (error) {
        logger.error("error in reading keyStore file: " + error);
    }
    return keyStore;
}

function getDecryptedAccount(path, password) {
    logger.debug("getDecryptedAccount(), path: " + path);
    const decryptedAccount = web3.eth.accounts.decrypt(JSON.parse(getKeystore(path)), password);
    logger.info('decryptedAccount.address: ' + decryptedAccount.address);
    return decryptedAccount;
}

/**
 * Obtains validators from the PoaNetworkConsensus contract
 * @returns {Promise.<*>}
 */
async function getValidators() {
    logger.debug('getValidators()');
    validatorsArr = await PoaNetworkConsensusContract.methods.getValidators().call();
    if (!validatorsArr || validatorsArr.length < 1) {
        errExit("Received invalid number of validators, array: " + validatorsArr);
    }
    logger.info('got validators, validatorsArr.length: ' + validatorsArr.length + ", validatorsArr: " + validatorsArr);
    return validatorsArr;
}