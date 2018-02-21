---
ansible_python_interpreter: /usr/bin/python3

ssh_root:
    - "{{ lookup('file', 'files/admins.pub') }}"

snmp_syslocation: "USA"
snmp_ipsubnet:    "172.16.0.0/16"

nameservers:
  - "8.8.8.8"
  - "8.8.4.4"

ntpservers:
  - "server 0.us.pool.ntp.org"
  - "server 1.us.pool.ntp.org"
  - "server 2.us.pool.ntp.org"
  - "server 3.us.pool.ntp.org"

NODE_PWD: "node.pwd" # don't change this one
NODE_SOURCE_DEB: "https://deb.nodesource.com/node_8.x"
PARITY_BIN_LOC: "https://d1h4xl4cr1h0mo.cloudfront.net/v1.9.2/x86_64-unknown-linux-gnu/parity"
PARITY_BIN_SHA256: "3604a030388cd2c22ebe687787413522106c697610426e09b3c5da4fe70bbd33"

SCRIPTS_MOC_BRANCH: "sokol"
SCRIPTS_VALIDATOR_BRANCH: "sokol"
MAIN_REPO_FETCH: "poanetwork"
GENESIS_BRANCH: "sokol"
GENESIS_NETWORK_NAME: "Sokol"

MOC_ADDRESS: "0xe8ddc5c7a2d2f0d7a9798459c0104fdf5e987aca"
BLK_GAS_LIMIT: "8000000"

#restrict network access to instances
allow_bootnode_ssh: true
allow_bootnode_p2p: true
allow_bootnode_rpc: false

allow_netstat_ssh: true
allow_netstat_http: true

################################################################

NODE_FULLNAME: "${node_fullname}"
NODE_ADMIN_EMAIL: "${node_admin_email}"

NETSTATS_SERVER: "${netstat_server_url}"
NETSTATS_SECRET: "${netstat_server_secret}"
