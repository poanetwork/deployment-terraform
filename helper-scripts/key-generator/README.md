## Script to generate an ethereum keyfile

### Usage:
```
MOC_SECRET=<PASSWORD> NETWORK_NAME=<PATH_TO_FOLDER> node script.js
```

### Example:
```
MOC_SECRET=12345 NETWORK_NAME=. node script.js
```
this will save address (`0x...`) to `./moc` and json keystore file to `./moc.json`.
