const fs = require('fs');
const str = require('str');
const toml = require('toml');
const json2toml = require('json2toml');

// script flow control vars
if (process.env['LOG_LEVEL']) {
    var log_level = process.env['LOG_LEVEL']
}
else { 
   var log_level = 'INFO'
}

// input var files 
const MOC_KEY_PATH = process.env.MOC_KEY;
const NODE_PWD_PATH = process.env.NODE_PWD;
const MOC_ADDRESS_FILE_PATH = process.env.MOC_ADDRESS_FILE_PATH;
const MOC_ADDRESS = process.env.MOC_ADDRESS;
const CONTRACTS_JSON_PATH = process.env.CONTRACTS_JSON_PATH;
const SPEC_JSON_PATH = process.env.SPEC_JSON_PATH;

// input config template
const TESTS_TOML_PATH = process.env.TOML_PATH;

// outputs
if (process.env.OUTPUT_CONFIG_PATH) {
    var OUTPUT_CONFIG_PATH = process.env.OUTPUT_CONFIG_PATH
}
else {
    var OUTPUT_CONFIG_PATH = 'config.toml'
}

if (!TESTS_TOML_PATH || !NODE_PWD_PATH || !MOC_KEY_PATH) {
    console.error('Env variables that need to be set: TOML_PATH and NODE_PWD and MOC_KEY');
    process.exit(1);
}

// helpers

function debug(...txt) {
    if (log_level == 'DEBUG') {
        console.log(new Date().toISOString(), "DEBUG:" , ...txt);
    }
}

function log(...txt) {
    console.log(new Date().toISOString(), ...txt);
}

function get_json(fpath) {
    log('Parsing JSON from ' + fpath);
    return JSON.parse( fs.readFileSync(fpath, 'utf8') );
}

function get_toml(fpath) {
    log('Parsing toml from ' + fpath);
    return toml.parse( fs.readFileSync(fpath, 'utf8') );
}

function write_toml(fpath, toml) {
    log ('Write content of ' + toml + 'to ' + fpath)
    toml_str = json2toml(toml)
    fs.writeFileSync(fpath, toml_str);
}

// Get params

function get_url() {
    log ('Get URL variable from env')
    return process.env.EXTERNAL_URL;
}

function get_addressto() {
    log ('Get AddressTO variable from moc.key')
    const moc_key_json = get_json(MOC_KEY_PATH);
    var_addressto = "0x" + moc_key_json.address    
    return var_addressto
}

function get_passwordfrom() {
    log ('Get PasswordFrom variable from node.pwd')
    var_passwordfrom = fs.readFileSync(NODE_PWD_PATH, 'utf8').trim();
    return var_passwordfrom
}

function get_keystorepath() {
    log ('Get keyStorePath variable from env')
    return MOC_KEY_PATH
}

function get_var_from_env(varname) {
    log ('Variable ' + varname + ' is set in env, get from there')
    return process.env[varname]
}

function get_var_from_default(config, varname) {
    debug ('Variable ' + varname + ' has default, and it will be used')
    variable = config[varname]
    return variable 
}

// Process config

function process_toml_template(config) {
    log ('Process toml template')
    var toml_obj = {}
    for (varname in config) {

        var var_value

        // Defaulted vars
        var_value = get_var_from_default(config, varname)

        // Net specific vars,has specific processors 
        switch (varname) {
            case 'url':
                var_value = get_url()
                break
            case 'keyStorePath':
                var_value = get_keystorepath() 
                break
            case 'passwordFrom':
                var_value = get_passwordfrom()
                break
            case 'addressTo':
                var_value = get_addressto()
                break
        }
        
        // If variable in env, get it's value from there
        env_varname = varname.toUpperCase();
        if (process.env[varname]) {
             var_value = get_var_from_env(env_varname)
        }
        // Print calculated var_value to file
        toml_obj[varname] = var_value
    }
    return toml_obj 
}

config = get_toml(TESTS_TOML_PATH)
toml_obj = process_toml_template(config)
write_toml (OUTPUT_CONFIG_PATH, toml_obj)

// Process contracts json
// TODO: this should also be a function


if (!MOC_ADDRESS_FILE_PATH && !MOC_ADDRESS || !CONTRACTS_JSON_PATH || !SPEC_JSON_PATH) {
    console.error('Env variables that need to be set: (MOC_ADDRESS_FILE_PATH or MOC_ADDRESS) and CONTRACTS_JSON_PATH and SPEC_JSON_PATH');
    process.exit(1);
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

