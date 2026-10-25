#!/usr/bin/env bash
# Download the offline build assets for the PHP images into php/asset/
set -euo pipefail

cd "$(dirname "$0")/php/asset"

for ext in sqlsrv pdo_sqlsrv; do
    for ver in 5.13.3 5.12.0; do
        curl -fL -o "$ext-$ver.tgz" "https://pecl.php.net/get/$ext-$ver.tgz"
    done
done

curl -fL -o msodbcsql18_18.7.1.1-1_amd64.apk https://download.microsoft.com/download/ade174b7-8cea-4543-91a6-c33ae320c2f0/msodbcsql18_18.7.1.1-1_amd64.apk
