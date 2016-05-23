#!/bin/bash
curl -sS "https://s3.amazonaws.com/bosh-init-artifacts/bosh-init-0.0.91-linux-amd64" -o bosh-init-0.0.91-linux-amd64
chmod +x bosh-init-*
mv bosh-init-* /usr/bin/bosh-init

