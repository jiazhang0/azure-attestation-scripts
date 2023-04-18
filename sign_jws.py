#!/usr/bin/env python3

import argparse
import jwt
import hashlib
import base64
import sys
import cryptography
import json
from cryptography import x509
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature
from cryptography.hazmat.primitives import hashes

parser = argparse.ArgumentParser(
    description='Azure Attestation JWS Signing Tool')
parser.add_argument('-k', '--signing-key', type=str,
                    help='PEM formatted private key for JWS signing')
parser.add_argument('-p', '--payload', required=True, type=str,
                    help='File containing payload to be signed')
parser.add_argument('-c', '--signing-cert', type=str,
                    help='PEM formatted certificate for JWS verification')

args = parser.parse_args()

# Recognize payload
with open(args.payload, 'r') as f:
    line = f.readline().lstrip()
    # Policy to add
    if line.startswith('version='):
        is_policy = True
    # Policy signing certificate to add
    elif line.startswith('-----BEGIN CERTIFICATE-----'):
        is_policy = False
    # Try to generate an illegal JWS with empty payload but
    # requred by MAA policy reset API.
    elif line == '':
        is_policy = True
    else:
        print("Unrecognized input payload file")
        sys.exit(1)

# Read payload from file
with open(args.payload, 'rb') as f:
    payload_in = f.read()


def base64url_encode(bytes):
    return jwt.utils.base64url_encode(bytes).decode('utf-8')


def save_jws(jws_to_save, signed=True):
    name = "{}.jws".format(args.payload)
    with open(name, 'w') as f:
        f.write(jws_to_save)
    print("{} {} generated".format("Unsigned" if not signed else "Signed", name))


# Read private key for signing and verification
if args.signing_key:
    with open(args.signing_key, 'rb') as f:
        priv_key_in = f.read()
elif not is_policy:
    print("Only police in AAD trust model can be unsigned")
    sys.exit(1)
else:
    claim_set = {'AttestationPolicy': base64url_encode(payload_in)}
    jws_to_save = jwt.encode(claim_set, None, algorithm=None)
    save_jws(jws_to_save, False)
    sys.exit(0)

# Read certificate from file
if args.signing_cert:
    with open(args.signing_cert, 'rb') as f:
        signing_cert_in = f.read()
else:
    signing_cert_in = None

signing_cert = x509.load_pem_x509_certificate(signing_cert_in)
signing_cert_der = signing_cert.public_bytes(
    encoding=serialization.Encoding.DER)

# Generate JWS with header containing public key
jose_header = {
    # MAA doesn't recognize the 'typ' filed in JWS when adding
    # signed policy. Setting this filed to be empty allows jwt
    # library to remove this field in the resulting JWS.
    'typ': '',
    'alg': 'RS256',
    'x5c': [base64.b64encode(signing_cert_der).decode('utf-8')]
}

if is_policy == False:
    signing_cert_to_add = x509.load_pem_x509_certificate(payload_in)
    signing_cert_der_to_add = signing_cert_to_add.public_bytes(
        encoding=serialization.Encoding.DER)
    pub_key_to_add = signing_cert_to_add.public_key()

    # Extract public key information and format in JWK
    jwk = {
        "kty": 'RSA',
        # "kid": 'example.org',
        "use": 'sig',
        "alg": 'RS256',
        "n": base64url_encode(pub_key_to_add.public_numbers().n.to_bytes(256, 'big')),
        "e": base64url_encode(pub_key_to_add.public_numbers().e.to_bytes(4, 'big')),
        'x5c': [base64.b64encode(signing_cert_der_to_add).decode('utf-8')],
        'x5t': base64url_encode(signing_cert_to_add.fingerprint(hashes.SHA1())),
        'x5t#S256': base64url_encode(signing_cert_to_add.fingerprint(hashes.SHA256()))
    }

    claim_set = {
        'policyCertificate': jwk
    }
else:
    claim_set = {
        'AttestationPolicy': base64url_encode(payload_in.decode().encode('utf-8'))
    }

priv_key = cryptography.hazmat.primitives.serialization.load_pem_private_key(
    priv_key_in,
    password=None,
)

if payload_in != b'':
    jws_to_save = jwt.encode(claim_set, priv_key_in,
                             algorithm='RS256', headers=jose_header)
else:
    # MAA policy reset API cannot recognize 'typ'.
    del jose_header['typ']

    # There is no way to generate a JWS without payload required by MAA
    # using standard jwt library, such as <jost_header>..<signature>.
    # Instead, we have to manually generate such an illegal JWS.
    encoded_header = base64url_encode(json.dumps(jose_header).encode('utf-8'))
    sig = priv_key.sign(
        (encoded_header + ".").encode('utf-8'),
        padding.PKCS1v15(),
        hashes.SHA256(),
    )
    encoded_sig = base64url_encode(sig)
    jws_to_save = f"{encoded_header}..{encoded_sig}"

# print(json.dumps(jws_to_save, indent=4))

# Verify signature using the exported public key
pub_key_to_verify = signing_cert.public_key()
if payload_in != b'':
    if jwt.decode(jws_to_save, pub_key_to_verify, algorithms=['RS256']) != claim_set:
        print('The signing certificate is not signed by the private signing key')
        sys.exit(1)
else:
    parts = jws_to_save.split('.')

    try:
        pub_key_to_verify.verify(
            base64.urlsafe_b64decode(parts[2] + '=' * (4 - len(parts[2]) % 4)),
            (parts[0] + ".").encode('utf-8'),
            padding.PKCS1v15(),
            algorithm=hashes.SHA256()
        )
    except:
        print('The signing certificate is not signed by the private signing key')
        sys.exit(1)

save_jws(jws_to_save)
