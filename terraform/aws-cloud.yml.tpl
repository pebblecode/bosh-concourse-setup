#cloud-init
# vim: ft=yaml:ts=2:sw=2:et
write_files:
- path: /home/ubuntu/concourse-cloud-config.yaml 
  permissions: 0644
  content: |
    ---
    azs:
    - name: z1
      cloud_properties: {availability_zone: ${availability_zone}}

    vm_types:
    - name: concourse_standalone
      cloud_properties:
        instance_type: t2.medium
        ephemeral_disk: {size: 5000, type: gp2}
        elbs: [${concourse_elb}]
    - name: concourse_web
      cloud_properties:
        instance_type: t2.medium
        ephemeral_disk: {size: 3000, type: gp2}
        elbs: [${concourse_elb}]
    - name: concourse_db
      cloud_properties:
        instance_type: t2.medium
        ephemeral_disk: {size: 3000, type: gp2}
    - name: concourse_worker
      cloud_properties:
        instance_type: t2.medium
        ephemeral_disk: {size: 3000, type: gp2}
    - name: default
      cloud_properties:
        instance_type: t2.micro
        ephemeral_disk: {size: 30000, type: gp2}
    - name: large
      cloud_properties:
        instance_type: m4.large
        ephemeral_disk: {size: 30000, type: gp2}

    disk_types:
    - name: default
      disk_size: 3000
      cloud_properties: {type: gp2}
    - name: large
      disk_size: 50_000
      cloud_properties: {type: gp2}

    networks:
    - name: default
      type: manual
      subnets:
      - range: ${subnet_cidr}
        gateway: 10.0.0.1
        az: z1
        static: [10.0.0.6]
        reserved: [10.0.0.1-10.0.0.5]
        dns: [10.0.0.2]
        cloud_properties: {subnet: ${subnet_id}}
    - name: vip
      type: vip

    compilation:
      workers: 2
      reuse_compilation_vms: true
      az: z1
      vm_type: default
      network: default
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
