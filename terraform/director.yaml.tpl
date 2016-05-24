#cloud-config
# vim: ft=yaml:ts=2:sw=2:et
write_files:
- path: /home/ubuntu/director.yaml
  permissions: 0644
  content: |
    ---
    name: bosh

    releases:
    - name: bosh
      url: https://bosh.io/d/github.com/cloudfoundry/bosh?v=256.2
      sha1: ff2f4e16e02f66b31c595196052a809100cfd5a8
    - name: bosh-aws-cpi
      url: https://bosh.io/d/github.com/cloudfoundry-incubator/bosh-aws-cpi-release?v=52
      sha1: dc4a0cca3b33dce291e4fbeb9e9948b6a7be3324

    resource_pools:
    - name: vms
      network: private
      stemcell:
        url: https://bosh.io/d/stemcells/bosh-aws-xen-hvm-ubuntu-trusty-go_agent?v=3232.3
        sha1: 1fe87c0146ad1f3b55eeed5a80ce35c01b4eb6d9
      cloud_properties:
        instance_type: m3.medium
        ephemeral_disk: {size: 25_000, type: gp2}
        availability_zone: ${availability_zone}
        iam_instance_profile: ${director_iam_instance_profile_name}

    disk_pools:
    - name: disks
      disk_size: 20_000
      cloud_properties: {type: gp2}

    networks:
    - name: private
      type: manual
      subnets:
      - range: ${subnet_cidr}
        gateway: 10.0.0.1
        dns: [10.0.0.2]
        cloud_properties: { subnet: ${subnet_id} }
    - name: public
      type: vip

    jobs:
    - name: bosh
      instances: 1

      templates:
      - {name: nats, release: bosh}
      - {name: postgres, release: bosh}
      - {name: blobstore, release: bosh}
      - {name: director, release: bosh}
      - {name: health_monitor, release: bosh}
      - {name: registry, release: bosh}
      - {name: aws_cpi, release: bosh-aws-cpi}

      resource_pool: vms
      persistent_disk_pool: disks

      networks:
      - name: private
        static_ips: [10.0.0.6]
        default: [dns, gateway]

      properties:
        nats:
          address: 127.0.0.1
          user: nats
          password: ${bosh_password}

        postgres: &db
          listen_address: 127.0.0.1
          host: 127.0.0.1
          user: postgres
          password: ${bosh_password}
          database: bosh
          adapter: postgres

        registry:
          address: 10.0.0.6
          host: 10.0.0.6
          db: *db
          http: {user: admin, password: ${bosh_password}, port: 25777}
          username: admin
          password: ${bosh_password}
          port: 25777

        blobstore:
          address: 10.0.0.6
          port: 25250
          provider: dav
          director: {user: director, password: ${bosh_password}}
          agent: {user: agent, password: ${bosh_password}}

        director:
          address: 127.0.0.1
          name: eb-bosh
          db: *db
          cpi_job: aws_cpi
          max_threads: 10
          user_management:
            provider: local
            local:
              users:
              - {name: admin, password: ${bosh_password}}
              - {name: hm, password: ${bosh_password}}

        hm:
          director_account: {user: hm, password: ${bosh_password}}
          resurrector_enabled: true

        aws: &aws
          credentials_source: env_or_profile
          default_iam_instance_profile: ${director_iam_instance_profile_name}
          default_security_groups: [${security_group}]
          default_key_name: ${key_name}
          region: ${aws_region}

        agent: {mbus: "nats://nats:${bosh_password}@10.0.0.6:4222"}

        ntp: &ntp [0.pool.ntp.org, 1.pool.ntp.org]

    cloud_provider:
      template: {name: aws_cpi, release: bosh-aws-cpi}

      ssh_tunnel:
        host: 10.0.0.6 # <--- Replace with your Elastic IP address
        port: 22
        user: vcap
        private_key: ${provisioned_private_key_path} # Path relative to this manifest file

      mbus: "https://mbus:${bosh_password}@10.0.0.6:6868" # <--- Replace with Elastic IP

      properties:
        aws: *aws
        agent: {mbus: "https://mbus:${bosh_password}@0.0.0.0:6868"}
        blobstore: {provider: local, path: /var/vcap/micro_bosh/data/cache}
        ntp: *ntp
- path: /home/ubuntu/bosh.pem
  permissions: 0600
  content: |
    -----BEGIN RSA PRIVATE KEY-----
    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
    -----END RSA PRIVATE KEY-----

