# Deployment Automation

This repository contains ansible+terraform scripts to automate deployment of new networks resembling "POA Network".

Namely, the following operations are performed:
- Random account is generated for Master of Ceremony (MoC)

- Bytecode of the Network Consensus Contract is prepared

- Based on these data, genesis json file is prepared

- Netstat node is started

- Several (configurable number) bootnodes are started, `bootnodes.txt` is exchanged between them.

- Additionally, some more bootnodes can be started behind a Gateway, forming a publicly accessible RPC endpoint for the network. This endpoint is availble over `http`, but the user may later assign it a DNS name, generate valid ssl certificates and upload them to the Gateway config, turning this endpoint to `https`.

- Explorer node is started.

- MoC's node is started.

- Ceremony is performed on the MoC's node, i.e. other consensus contracts are deployed to the network.

- Several (configurable number) initial keys are generated.

- Subset (or all) of initial keys are converted into (mining + voting + payout) keys.

- For a subset (or for all) of converted keys, validator nodes are started.

- Simple tests can be run against the network: (1) check that txs are getting mined (2) check that all validators mine blocks (only makes sense if validator nodes were started for all mining keys).

- Artifacts (`spec.json`, `bootnodes.txt`, `contracts.json`, ...) are stored on the MoC's node.

- `hosts` file is generated on the user's machine containing ip addresses of all nodes and their respective roles.

Most of the work is done by `ansible`, but to bring up the infrastructure, ansible calls `terraform`.

## Usage

Currently, only deployment to Azure is supported:
[Azure deployment README](azure/README.md)

