const fs = require('fs');

const MOC_ADDRESS_FILE_PATH = process.env.MOC_ADDRESS_FILE_PATH;
const MOC_ADDRESS = process.env.MOC_ADDRESS;
const CONTRACTS_JSON_PATH = process.env.CONTRACTS_JSON_PATH;
const SPEC_JSON_PATH = process.env.SPEC_JSON_PATH;

function log(...txt) {
    console.log(new Date().toISOString(), ...txt);
}

if (!MOC_ADDRESS_FILE_PATH && !MOC_ADDRESS || !CONTRACTS_JSON_PATH || !SPEC_JSON_PATH) {
    console.error('Env variables that need to be set: (MOC_ADDRESS_FILE_PATH or MOC_ADDRESS) and CONTRACTS_JSON_PATH and SPEC_JSON_PATH');
    process.exit(1);
}

function get_json(fpath) {
    log('Parsing JSON from ' + fpath);
    return JSON.parse( fs.readFileSync(fpath, 'utf8') );
}

const contracts_json = get_json(CONTRACTS_JSON_PATH);
const spec_json = get_json(SPEC_JSON_PATH);
log('networkID = ' + spec_json.params.networkID);

var engine_type = Object.keys(spec_json.engine)[0];
log('engine_type = ' + engine_type);
var multi = spec_json.engine[engine_type].params.validators.multi;
log('multi = ' + JSON.stringify(multi));
var multies = Object.keys(multi);
var contractObj = multi[ multies[multies.length-1] ];
contracts_json.POA_ADDRESS = (contractObj.safeContract || contractObj.contract);
log('contracts_json.POA_ADDRESS = ' + contracts_json.POA_ADDRESS);

if (MOC_ADDRESS) {
    contracts_json.MOC = MOC_ADDRESS;
    log('contracts_json.MOC = ' + contracts_json.MOC);
}
else if (MOC_ADDRESS_FILE_PATH) {
    contracts_json.MOC = fs.readFileSync(MOC_ADDRESS_FILE_PATH, 'utf8').trim();
    log('contracts_json.MOC = ' + contracts_json.MOC);
}
else {
    throw new Error('No MOC_ADDRESS_FILE_PATH or MOC_ADDRESS provided');
}

log('Saving contracts.json...');
fs.writeFileSync(CONTRACTS_JSON_PATH, JSON.stringify(contracts_json, null, 4));

log('Done');
