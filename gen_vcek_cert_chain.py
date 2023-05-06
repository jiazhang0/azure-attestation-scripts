#!/usr/bin/env python3

import json

with open('samples/security-context/uvm_host_amd_cert.json', 'r') as f:
    amd_cert = json.load(f)

print(amd_cert['vcekCert'] + amd_cert['certificateChain'])
