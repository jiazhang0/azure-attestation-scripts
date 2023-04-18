#!/bin/bash

set -e

source ./env.sh

function cleanup() {
  set +e
  ./reset_policy.sh
  ./delete_policy_signing_cert.sh
}
trap cleanup ERR

./add_policy_signing_cert.sh
./list_policy_signing_cert.sh
./configure_policy.sh
./show_policy.sh
./reset_policy.sh
./delete_policy_signing_cert.sh

echo "All tests complete!"
