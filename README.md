BOSH Director & Concourse Bootstrap
===================================

This project achieves the following:

- Preparation of an AWS environment for BOSH & Concourse
- Deployment of a new BOSH Director using bosh-init
- Deployment of a new Concourse cluster, or standalone server

Terraform is used to setup the base network and security infrastructure, including an ELB for Concourse.

Requirements
-----

- Install [terraform](https://www.terraform.io/intro/getting-started/install.html)
- Install [bosh-init](https://bosh.io/docs/install-bosh-init.html)
- Install the [bosh_cli](https://bosh.io/docs/bosh-cli.html)

Ensure you have created a `terraform/terraform.tfvars` file with your variables, or set suitable [environment variables](https://www.terraform.io/docs/configuration/variables.html). An example tfvars file can be found in `terraform/terraform.tfvars.example`

Assumptions
-----

You already have:

- A Route53 Zone in AWS.
- An EC2 SSH keypair
- An SSL certificate in AWS for your Concourse ELB

Usage
-----

Set your desired AWS region in `terrform/variables.tf`. Ensure terraform is in your path, then apply the configuration to prepare the IaaS for BOSH and Concourse:

```
cd terraform/
terraform apply
```

Download the bosh_init script with `./bosh_init.sh`
You are ready to deploy the BOSH Director
```
bosh-init deploy director.yml
```

Go and make a cup of tea.

Once the director is deployed, target it and apply your cloud-config for AWS.

```
bosh target <your EIP address>
bosh update cloud-config aws-cloud.yml
```

Set the Concourse URL and password in these environment variables:

```
$CONCOURSE_PASSWORD
$CONCOURSE_URL
$GITHUB_CLIENT_ID
$GITHUB_CLIENT_SECRET
```

Create a concourse manifest for small cluster:
```
./bin/make_manifest_concourse-cluster.sh
```

Upload the necessary stemcell & releases, then deploy concourse:
```
bosh upload stemcell https://bosh.io/d/stemcells/bosh-aws-xen-hvm-ubuntu-trusty-go_agent?v=3232.8
osh upload release https://bosh.io/d/github.com/concourse/concourse?v=1.3.0
bosh upload release https://bosh.io/d/github.com/cloudfoundry-incubator/garden-runc-release?v=0.3.0
bosh deployment concourse.yml
bosh deploy
```

Congratulations, you should now be able to see your new CI server at https://your-concourse-url.
