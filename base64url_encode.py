#!/usr/bin/env python3

import sys, jwt

with open(sys.argv[1], 'rb') as f:
    payload_in = f.read()

print(jwt.utils.base64url_encode(payload_in).decode('utf-8'))
