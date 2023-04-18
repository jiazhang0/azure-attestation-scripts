# Azure Attestation Scripts

## Purpose

These scripts are used to build and test [Azure Attestation](https://azure.microsoft.com/en-us/products/azure-attestation) through [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/service-page/azure%20attestation?view=azure-cli-latest) and [REST APIs](https://learn.microsoft.com/en-us/rest/api/attestation/) under the **Isolated** and **AAD** trust models. The "Isloated" trust model is enabled only if the root policy signing certificate is imported along with the creation of MAA instance. By defaylt, the "AAD" trust model is enabled.

## Preparation

Please modify env.sh.in according to your Azure subscription and save it as env.sh, then run
```shell
source env.sh
```

In the following steps, you will need to manually create policy signing keys for "Isolated" trust mode. If not necessary, just omit the following steps.

Next step is to create a root policy signing certificate and create the MAA instance with it, such as:
```shell
openssl genrsa -out root_policy_signing_private_key.pem 2048
openssl rsa -in root_policy_signing_private_key.pem -pubout \
  -out root_policy_signing_public_key.pem
openssl req -x509 -new -key root_policy_signing_private_key.pem \
  -out root_policy_signing_cert.pem -days 3650
az attestation create \
  --name $AZURE_MAA_CUSTOM_RESOURCE_NAME \
  --resource-group $AZURE_RESOURCE_GROUP \
  --location $AZURE_RESOURCE_GROUP_LOCATION \
  --certs-input-path root_policy_signing_cert.pem
```

The last step here is to create a policy signing certificate used to sign the policy, such as:
```shell
openssl genrsa -out my_policy_signing_private_key.pem 2048
openssl rsa -in my_policy_signing_private_key.pem -pubout \
  -out my_policy_signing_public_key.pem
openssl req -x509 -new -key my_policy_signing_private_key.pem \
  -out my_policy_signing_cert.pem -days 3650
```

The resulting `my_policy_signing_cert.pem` will be used later.

## Usage

For a quick start, simply run `ci_test.sh` to validate Azure Attestation functions.

You can also run single script to execute the specified functions, including:
- [create_maa_instance.sh](create_maa_instance.sh): create a MAA instance
- [add_policy_signing_cert.sh](add_policy_signing_cert.sh): add a policy signing certificate
- [list_policy_signing_cert.sh](list_policy_signing_cert.sh): list all policy signing certificates added
- [configure_policy.sh](configure_policy.sh): configure a policy
- [show_policy.sh](show_policy.sh): show the configured policy
- [reset_policy.sh](reset_policy.sh): reset the configured policy
- [delete_policy_signing_cert.sh](delete_policy_signing_cert.sh): delete the policy signing certificate added
- [delete_maa_instance.sh](delete_maa_instance.sh): delete the MAA instance
- [decode.sh](decode.sh): decode the resulting JWT or base64-encoded x509 certificate
- [sign_jws.py](sign_jws.py): generate a JWS as request parameter required by Azure Attestation
