#!/usr/bin/env python3

from cose.messages import CoseMessage

with open("samples/security-context/uvm_reference_info.bin", "rb") as f:
    encoded = f.read()

decoded = CoseMessage.decode(encoded)
print(decoded)
