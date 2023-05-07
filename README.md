# Azure Attestation Scripts

## Purpose

These scripts are used to build and test [Azure Attestation](https://azure.microsoft.com/en-us/products/azure-attestation) through [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/service-page/azure%20attestation?view=azure-cli-latest) and [REST APIs](https://learn.microsoft.com/en-us/rest/api/attestation/) under the **Isolated** and **AAD** trust models. The "Isloated" trust model is enabled only if the root policy signing certificate is imported along with the creation of MAA instance. By default, the "AAD" trust model is used.

## Preparation

Please modify env.sh.in according to your Azure subscription and save it as env.sh, then run:
```shell
source env.sh
```

In the following steps, you need to manually create the policy signing keys for "Isolated" trust model. Using "AAD" trust model can omit the following steps.

Next step is to create a root policy signing certificate and create a MAA instance with it, such as:
```shell
openssl genrsa -out root_policy_signing_private_key.pem 2048
openssl req -x509 -new -key root_policy_signing_private_key.pem \
  -out root_policy_signing_cert.pem -days 3650
az attestation create \
  --name $AZURE_MAA_CUSTOM_RESOURCE_NAME \
  --resource-group $AZURE_RESOURCE_GROUP \
  --location $AZURE_RESOURCE_GROUP_LOCATION \
  --certs-input-path root_policy_signing_cert.pem
```

The last step is to create a policy signing certificate used to sign a policy, such as:
```shell
openssl genrsa -out my_policy_signing_private_key.pem 2048
openssl req -x509 -new -key my_policy_signing_private_key.pem \
  -out my_policy_signing_cert.pem -days 3650
```

Note: all the resulting *.pem will be used by the scripts.

## Usage

For a quick start, simply run `ci_test.sh` to validate Azure Attestation functions.

You can also run a single script to execute the specified function.

- [create_maa_instance.sh](create_maa_instance.sh): create a MAA instance
- [get_metadata_configuration.sh](get_metadata_configuration.sh): get MAA metadata configuration
- [get_token_signer_certs.sh](get_token_signer_certs.sh): get the token signer certificates
- [add_policy_signing_cert.sh](add_policy_signing_cert.sh): add a policy signing certificate
- [list_policy_signing_cert.sh](list_policy_signing_cert.sh): list all policy signing certificates added
- [configure_policy.sh](configure_policy.sh): configure a policy
- [show_policy.sh](show_policy.sh): show the configured policy
- [reset_policy.sh](reset_policy.sh): reset the configured policy
- [delete_policy_signing_cert.sh](delete_policy_signing_cert.sh): delete the policy signing certificate added
- [delete_maa_instance.sh](delete_maa_instance.sh): delete the MAA instance
- [decode.sh](decode.sh): decode the resulting JWT or base64-encoded x509 certificate
- [sign_jws.py](sign_jws.py): generate a JWS as request parameter required by Azure Attestation
- [dump_report.sh](dump_report.sh): dump the content of sample SNP Attestation Report
