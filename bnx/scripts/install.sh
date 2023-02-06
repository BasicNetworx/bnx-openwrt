#!/bin/bash
#
# Install package feeds.
#

PROG=$(basename $0)

print_help() {
    echo "usage: $PROG --product <product> [options]"
    echo "product can be one of:"
    while read -r model; do echo "  * $model"; done < bnx/models
}

while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        --product)
        product="$2"
        shift # past argument
        shift # past value
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

product=$(cat bnx/models | grep "^$product$")

if [ -z $product ]; then
    echo "Must specify a valid product"
    print_help
    exit 1
fi

echo "Installing packages for product: $product"

set -e

## Fetch and instal package feeds
cp bnx/feeds/$product.conf feeds.conf
./scripts/feeds update -a
./scripts/feeds install -a
