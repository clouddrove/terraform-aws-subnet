<!-- This file was automatically generated by the `geine`. Make all changes to `README.yaml` and run `make readme` to rebuild this file. -->

<p align="center"> <img src="https://user-images.githubusercontent.com/50652676/62349836-882fef80-b51e-11e9-99e3-7b974309c7e3.png" width="100" height="100"></p>


<h1 align="center">
    Terraform AWS Subnet
</h1>

<p align="center" style="font-size: 1.2rem;"> 
    Terraform module to create public, private and public-private subnet with network acl, route table, Elastic IP, nat gateway, flow log.
     </p>

<p align="center">

<a href="https://www.terraform.io">
  <img src="https://img.shields.io/badge/Terraform-v1.1.7-green" alt="Terraform">
</a>
<a href="LICENSE.md">
  <img src="https://img.shields.io/badge/License-APACHE-blue.svg" alt="Licence">
</a>
<a href="https://github.com/clouddrove/terraform-aws-subnet/actions/workflows/tfsec.yml">
  <img src="https://github.com/clouddrove/terraform-aws-subnet/actions/workflows/tfsec.yml/badge.svg" alt="tfsec">
</a>
<a href="https://github.com/clouddrove/terraform-aws-subnet/actions/workflows/terraform.yml">
  <img src="https://github.com/clouddrove/terraform-aws-subnet/actions/workflows/terraform.yml/badge.svg" alt="static-checks">
</a>


</p>
<p align="center">

<a href='https://facebook.com/sharer/sharer.php?u=https://github.com/clouddrove/terraform-aws-subnet'>
  <img title="Share on Facebook" src="https://user-images.githubusercontent.com/50652676/62817743-4f64cb80-bb59-11e9-90c7-b057252ded50.png" />
</a>
<a href='https://www.linkedin.com/shareArticle?mini=true&title=Terraform+AWS+Subnet&url=https://github.com/clouddrove/terraform-aws-subnet'>
  <img title="Share on LinkedIn" src="https://user-images.githubusercontent.com/50652676/62817742-4e339e80-bb59-11e9-87b9-a1f68cae1049.png" />
</a>
<a href='https://twitter.com/intent/tweet/?text=Terraform+AWS+Subnet&url=https://github.com/clouddrove/terraform-aws-subnet'>
  <img title="Share on Twitter" src="https://user-images.githubusercontent.com/50652676/62817740-4c69db00-bb59-11e9-8a79-3580fbbf6d5c.png" />
</a>

</p>
<hr>


We eat, drink, sleep and most importantly love **DevOps**. We are working towards strategies for standardizing architecture while ensuring security for the infrastructure. We are strong believer of the philosophy <b>Bigger problems are always solved by breaking them into smaller manageable problems</b>. Resonating with microservices architecture, it is considered best-practice to run database, cluster, storage in smaller <b>connected yet manageable pieces</b> within the infrastructure. 

This module is basically combination of [Terraform open source](https://www.terraform.io/) and includes automatation tests and examples. It also helps to create and improve your infrastructure with minimalistic code instead of maintaining the whole infrastructure code yourself.

We have [*fifty plus terraform modules*][terraform_modules]. A few of them are comepleted and are available for open source usage while a few others are in progress.




## Prerequisites

This module has a few dependencies: 

- [Terraform 1.x.x](https://learn.hashicorp.com/terraform/getting-started/install.html)
- [Go](https://golang.org/doc/install)
- [github.com/stretchr/testify/assert](https://github.com/stretchr/testify)
- [github.com/gruntwork-io/terratest/modules/terraform](https://github.com/gruntwork-io/terratest)







## Examples


**IMPORTANT:** Since the `master` branch used in `source` varies based on new modifications, we suggest that you use the release versions [here](https://github.com/clouddrove/terraform-aws-subnet/releases).


Here are some examples of how you can use this module in your inventory structure:
### PRIVATE SUBNET
```hcl
  module "subnets" {
    source                = "clouddrove/terraform-aws-subnet/aws"
    version               = "1.3.0"
    name                  = "subnets"
    environment           = "test"
    label_order           = ["name", "environment"]
    nat_gateway_enabled   = true
    availability_zones    = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
    vpc_id                = module.vpc.vpc_id
    type                  = "private"
    cidr_block            = module.vpc.vpc_cidr_block
    ipv6_cidr_block       = module.vpc.ipv6_cidr_block
    public_subnet_ids     = ["subnet-xxxxxxxxxxxx", "subnet-xxxxxxxxxxxx"]
  }
```

### PUBLIC-PRIVATE SUBNET
```hcl
  module "subnets" {
    source              = "clouddrove/terraform-aws-subnet/aws"
    version             = "1.3.0"
    name                = "subnets"
    environment         = "test"
    label_order         = ["name", "environment"]
    nat_gateway_enabled = true
    availability_zones  = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
    vpc_id              = module.vpc.vpc_id
    type                = "public-private"
    igw_id              = module.vpc.igw_id
    cidr_block          = module.vpc.vpc_cidr_block
    ipv6_cidr_block     = module.vpc.ipv6_cidr_block
  }
```

  ### PUBLIC-PRIVATE SUBNET WITH SINGLE NET GATEWAY
```hcl
  module "subnets" {
    source              = "clouddrove/terraform-aws-subnet/aws"
    version             = "1.3.0"
    name                = "subnets"
    environment         = "test"
    label_order         = ["name", "environment"]
    availability_zones  = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
    nat_gateway_enabled = true
    single_nat_gateway  = true
    vpc_id              = module.vpc.vpc_id
    type                = "public-private"
    igw_id              = module.vpc.igw_id
    cidr_block          = module.vpc.vpc_cidr_block
    ipv6_cidr_block     = module.vpc.ipv6_cidr_block
  }
```

### PUBLIC SUBNET
```hcl
  module "subnets" {
    source             = "clouddrove/terraform-aws-subnet/aws"
    version            = "1.3.0"
    name               = "subnets"
    environment        = "test"
    label_order        = ["name", "environment"]
    availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
    vpc_id             = module.vpc.vpc_id
    type               = "public"
    igw_id             = module.vpc.igw_id
    cidr_block         = module.vpc.vpc_cidr_block
    ipv6_cidr_block    = module.vpc.ipv6_cidr_block
  }
```






## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| assign\_ipv6\_address\_on\_creation | Specify true to indicate that network interfaces created in the specified subnet should be assigned an IPv6 address. | `bool` | `false` | no |
| attributes | Additional attributes (e.g. `1`). | `list(any)` | `[]` | no |
| availability\_zones | List of Availability Zones (e.g. `['us-east-1a', 'us-east-1b', 'us-east-1c']`). | `list(string)` | `[]` | no |
| az\_ngw\_count | Count of items in the `az_ngw_ids` map. Needs to be explicitly provided since Terraform currently can't use dynamic count on computed resources from different modules. https://github.com/hashicorp/terraform/issues/10857. | `number` | `0` | no |
| az\_ngw\_ids | Only for private subnets. Map of AZ names to NAT Gateway IDs that are used as default routes when creating private subnets. | `map(string)` | `{}` | no |
| cidr\_block | Base CIDR block which is divided into subnet CIDR blocks (e.g. `10.0.0.0/16`). | `string` | n/a | yes |
| delimiter | Delimiter to be used between `organization`, `environment`, `name` and `attributes`. | `string` | `"-"` | no |
| enable\_acl | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| enable\_flow\_log | Enable subnet\_flow\_log logs. | `bool` | `false` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| environment | Environment (e.g. `prod`, `dev`, `staging`). | `string` | `""` | no |
| igw\_id | Internet Gateway ID that is used as a default route when creating public subnets (e.g. `igw-9c26a123`). | `string` | `""` | no |
| ipv4\_private\_cidrs | Subnet CIDR blocks (e.g. `10.0.0.0/16`). | `list(any)` | `[]` | no |
| ipv4\_public\_cidrs | Subnet CIDR blocks (e.g. `10.0.0.0/16`). | `list(any)` | `[]` | no |
| ipv6\_cidr\_block | Base CIDR block which is divided into subnet CIDR blocks (e.g. `10.0.0.0/16`). | `string` | n/a | yes |
| ipv6\_cidrs | Subnet CIDR blocks (e.g. `2a05:d018:832:ca02::/64`). | `list(any)` | `[]` | no |
| label\_order | Label order, e.g. `name`,`application`. | `list(any)` | `[]` | no |
| managedby | ManagedBy, eg 'CloudDrove'. | `string` | `"hello@clouddrove.com"` | no |
| map\_public\_ip\_on\_launch | Specify true to indicate that instances launched into the subnet should be assigned a public IP address. | `bool` | `true` | no |
| max\_subnets | Maximum number of subnets that can be created. The variable is used for CIDR blocks calculation. | `number` | `6` | no |
| name | Name  (e.g. `app` or `cluster`). | `string` | `""` | no |
| nat\_gateway\_enabled | Flag to enable/disable NAT Gateways creation in public subnets. | `bool` | `false` | no |
| private\_network\_acl\_id | Network ACL ID that is added to the private subnets. If empty, a new ACL will be created. | `string` | `""` | no |
| public\_network\_acl\_id | Network ACL ID that is added to the public subnets. If empty, a new ACL will be created. | `string` | `""` | no |
| public\_subnet\_ids | A list of public subnet ids. | `list(string)` | `[]` | no |
| repository | Terraform current module repo | `string` | `"https://github.com/clouddrove/terraform-aws-subnet"` | no |
| s3\_bucket\_arn | S3 ARN for vpc logs. | `string` | `""` | no |
| single\_nat\_gateway | Enable for only single NAT Gateway in one Availability Zone | `bool` | `false` | no |
| tags | Additional tags (e.g. map(`BusinessUnit`,`XYZ`). | `map(any)` | `{}` | no |
| traffic\_type | Type of traffic to capture. Valid values: ACCEPT,REJECT, ALL. | `string` | `"ALL"` | no |
| type | Type of subnets to create (`private` or `public`). | `string` | `""` | no |
| vpc\_id | VPC ID. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| private\_acl | The ID of the network ACL. |
| private\_route\_tables\_id | The ID of the routing table. |
| private\_subnet\_cidrs | CIDR blocks of the created private subnets. |
| private\_subnet\_cidrs\_ipv6 | CIDR blocks of the created private subnets. |
| private\_subnet\_id | The ID of the private subnet. |
| private\_tags | A mapping of private tags to assign to the resource. |
| public\_acl | The ID of the network ACL. |
| public\_route\_tables\_id | The ID of the routing table. |
| public\_subnet\_cidrs | CIDR blocks of the created public subnets. |
| public\_subnet\_cidrs\_ipv6 | CIDR blocks of the created public subnets. |
| public\_subnet\_id | The ID of the subnet. |
| public\_tags | A mapping of public tags to assign to the resource. |




## Testing
In this module testing is performed with [terratest](https://github.com/gruntwork-io/terratest) and it creates a small piece of infrastructure, matches the output like ARN, ID and Tags name etc and destroy infrastructure in your AWS account. This testing is written in GO, so you need a [GO environment](https://golang.org/doc/install) in your system. 

You need to run the following command in the testing folder:
```hcl
  go test -run Test
```



## Feedback 
If you come accross a bug or have any feedback, please log it in our [issue tracker](https://github.com/clouddrove/terraform-aws-subnet/issues), or feel free to drop us an email at [hello@clouddrove.com](mailto:hello@clouddrove.com).

If you have found it worth your time, go ahead and give us a ★ on [our GitHub](https://github.com/clouddrove/terraform-aws-subnet)!

## About us

At [CloudDrove][website], we offer expert guidance, implementation support and services to help organisations accelerate their journey to the cloud. Our services include docker and container orchestration, cloud migration and adoption, infrastructure automation, application modernisation and remediation, and performance engineering.

<p align="center">We are <b> The Cloud Experts!</b></p>
<hr />
<p align="center">We ❤️  <a href="https://github.com/clouddrove">Open Source</a> and you can check out <a href="https://github.com/clouddrove">our other modules</a> to get help with your new Cloud ideas.</p>

  [website]: https://clouddrove.com
  [github]: https://github.com/clouddrove
  [linkedin]: https://cpco.io/linkedin
  [twitter]: https://twitter.com/clouddrove/
  [email]: https://clouddrove.com/contact-us.html
  [terraform_modules]: https://github.com/clouddrove?utf8=%E2%9C%93&q=terraform-&type=&language=
