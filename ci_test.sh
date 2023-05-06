#!/bin/bash

set -e

source ./env.sh

function cleanup() {
  set +e
  ./delete_maa_instance.sh
}
trap cleanup ERR

./create_maa_instance.sh
./add_policy_signing_cert.sh
./list_policy_signing_cert.sh
./configure_policy.sh
./show_policy.sh
./reset_policy.sh
./delete_policy_signing_cert.sh
./delete_maa_instance.sh

echo "All tests complete!"
