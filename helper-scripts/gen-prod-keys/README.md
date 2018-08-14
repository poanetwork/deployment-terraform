Script to generate production keys (mining + voting + payout) from initial key

### Usage:
1. clone the repository
```
git clone https://github.com/phahulin/gen-prod-keys.git
cd gen-prod-keys
```

2. install dependencies
```
npm install
```

3. place initial key's json keystore file into `keystore` folder. Filename should contain the corresponding address (e.g. `d61a7010e9b40819df0045cbcd0c89c51ad18fe1.json`)

4. run the script
```
node index.js <KEYSMANAGER_CONTRACT_ADDRESS>
```
* `0xADDRESS` - initial key's address with `0x` prefix
* `KEYSTORE_PASSWORD` - password for initial key's json keystore file
* `KEYSMANAGER_CONTRACT_ADDRESS` - `0x`-prefixed address of the keys manager contract of the network.

5. generated mining, voting and payout json keystore files and their passwords will be saved in `production-keys/validator-<0xADDRESS>/` folder:
```
production-keys/
└── validator-0xd61a7010e9b40819df0045cbcd0c89c51ad18fe1/
    ├── mining-0x05644f37b1f150d971556f4adc91c6a918d8faf6.json
    ├── mining-0x05644f37b1f150d971556f4adc91c6a918d8faf6.key
    ├── payout-0xde9165519df2c4864a16704b3a553289da0497f9.json
    ├── payout-0xde9165519df2c4864a16704b3a553289da0497f9.key
    ├── voting-0x1e91ba7450cd6ab8ea76ea8b4dc8ea4a8b4657fe.json
    └── voting-0x1e91ba7450cd6ab8ea76ea8b4dc8ea4a8b4657fe.key
```
