# Tests for checking network workability

Test in the <code>tests.js</code> file sends transactions one by one (after confirming), checks they were mined and all validators
 mined at least one transaction in a few rounds. Then checks if any validator missed their turn in the last round.
 Before this test waits some time for a few empty blocks were mined for including them to the test.
 <br>
 Results are logged to the log files. <br>
 <code>combined.log</code> will contain all logs and 
 <code>error.log</code> only failed test results and any other errors.
 <br>
 <br>
<code>contracts</code> folder contains abi and address of needed contracts.<br>
<code>contracts.json</code> is an example of file with contracts addresses. 
Replace after network deployment with file contains contracts addresses.
<br>
<br>
<code>config-sample.toml</code> is an example of file with settings. Needs to be renamed to <code>config.toml</code>
and filled with valid settings (as path to the keystore file, password, rpc endpoint, timeoutSeconds enough for a couple blocks creation and other configurations). 

<h2>Setup</h2>

1.Clone the repository

```sh
git clone https://github.com/poanetwork/deployment-terraform.git
cd ./deployment-terraform/helper-scripts/network-tests
```

2.Install dependencies <br>

```sh
npm install
```

3.Edit <code>config-sample.toml</code> and <code>contracts.json</code> files. <br>

4.Run

```sh
node ./tests.js
```
