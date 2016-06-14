#!/bin/bash
#
#  Please set the following environment variables:
#  $GITHUB_CLIENT_ID
#  $GITHUB_CLIENT_SECRET
#  $CONCOURSE_URL
#  $CONCOURSE_PASSWORD

DIRECTOR_UUID=`bosh status --uuid`

echo "director_uuid = $DIRECTOR_UUID"
echo "concourse url = $CONCOURSE_URL"

cat >concourse.yml <<YAML
---
name: concourse

director_uuid: $DIRECTOR_UUID

releases:
- name: concourse
  version: latest
- name: garden-linux
  version: latest

stemcells:
- alias: trusty
  os: ubuntu-trusty
  version: latest

instance_groups:
- name: web
  instances: 1
  vm_type: concourse_web
  stemcell: trusty
  azs: [z1]
  networks: [{name: default}]
  jobs:
  - name: atc
    release: concourse
    properties:
      external_url: https://build.ci.inoket.com


      github_auth:
        client_id: $GITHUB_CLIENT_ID
        client_secret: 67a59e9ee2d27f2044a2212290294abc49a2258c
        authorize:
          - organization: pebblecode
            teams: [cirrus]
      postgresql_database: &atc_db atc
  - name: tsa
    release: concourse
    properties: {}

- name: db
  instances: 1
  vm_type: concourse_db
  stemcell: trusty
  persistent_disk_type: default
  azs: [z1]
  networks: [{name: default}]
  jobs:
  - name: postgresql
    release: concourse
    properties:
      databases:
      - name: *atc_db
        # make up a role and password
        role: dbrole
        password: $CONCOURSE_PASSWORD

- name: worker
  instances: 1
  vm_type: concourse_worker
  stemcell: trusty
  azs: [z1]
  networks: [{name: default}]
  jobs:
  - name: groundcrew
    release: concourse
    properties: {}
  - name: baggageclaim
    release: concourse
    properties: {}
  - name: garden
    release: garden-linux
    properties:
      garden:
        listen_network: tcp
        listen_address: 0.0.0.0:7777

update:
  canaries: 1
  max_in_flight: 1
  serial: false
  canary_watch_time: 1000-60000
  update_watch_time: 1000-60000
YAML

