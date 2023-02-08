#!/bin/bash
#
# Configure build settings.
#

PROG=$(basename $0)

print_help() {
    echo "usage: $PROG --product <product> [options]"
    echo "product can be one of:"
    while read -r model; do echo "  * $model"; done < bnx/models
    echo "options:"
    echo "  --version <version>     : set version for release builds (default is development)"
    echo "  --bnxcloud <deployment> : connect to specified bnxcloud deployment (default is bnxcloud-beta)"
    echo "  --skip-secrets          : skip fetching device/firmware secrets"
}

print_fetch_secret_error() {
    echo "Failed to fetch device/firmware secrets."
    echo "Do you have the aws cli installed?"
    echo "Is your AWS access key id and secret access key set correctly?"
    echo "If you want to skip fetching the device/firmware secrets,"
    echo "use the --skip-secrets option."
}

fetch_secret() {
    secret_id=$1

    secret_json=$(aws secretsmanager get-secret-value --secret-id $secret_id 2>/dev/null)
    if [ $? -ne 0 ]; then
        return 1
    fi

    secret=$(echo $secret_json | jq -r '.SecretString | fromjson | .secret')
    if [ $? -ne 0 ]; then
        return 1
    fi

    export "$2=$secret"

    return 0
}

SKIP_SECRETS=0
version="development"
bnxcloud="bnxcloud-beta"

while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        --product)
        product="$2"
        shift # past argument
        shift # past value
        ;;
        --version)
        version="$2"
        shift # past argument
        shift # past value
        ;;
        --skip-secrets)
        SKIP_SECRETS=1
        shift # past argument
        ;;
        --help)
        print_help
        exit 0
        ;;
        *)
        echo "Unknown argument"
        print_help
        exit 0
    esac
done

device_secret="missing"
firmware_secret="missing"
product=$(cat bnx/models | grep "^$product$")

if [ -z $product ]; then
    echo "Must specify a valid product"
    print_help
    exit 1
fi

echo "Configuring build for product: $product"

if [ $SKIP_SECRETS -eq 0 ]; then
    echo "Fetching device/firmware secrets..."
    fetch_secret "bnx-device-secret" device_secret
    if [ $? -ne 0 ]; then
        print_fetch_secret_error
        exit 1
    fi
    fetch_secret "bnx-firmware-secret" firmware_secret
    if [ $? -ne 0 ]; then
        print_fetch_secret_error
        exit 1
    fi

    echo "Successfully fetched device/firmware secrets."
fi

set -e

## Configure build settings
cp bnx/configs/$product.config .config
echo 'CONFIG_VERSION_NUMBER="'$version'"' >> .config
echo 'CONFIG_BNX_CLOUD_API_ENDPOINT="'$bnxcloud'"' >> .config
echo 'CONFIG_BNX_DEVICE_SECRET="'$device_secret'"' >> .config
echo 'CONFIG_BNX_FIRMWARE_SECRET="'$firmware_secret'"' >> .config
make defconfig
