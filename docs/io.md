## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| additional\_private\_routes\_for\_all | Routes added to every private route table. With a single NAT Gateway, the route is added once to the shared private route table.<br>Use this when you want uniform routing across all AZs.<br><br>Example:<br>  additional\_private\_routes\_for\_all = [<br>    {<br>      destination\_cidr\_block = "10.100.0.0/16"<br>      gateway\_id             = aws\_vpn\_gateway.this.id<br>    }<br>  ] | `list(map(string))` | `[]` | no |
| additional\_private\_routes\_per\_subnet | Routes added to specific AZ private route tables only.<br>Key = AZ name or AZ ID, Value = list of routes for that AZ.<br>AZs not listed here get no additional per-subnet routes.<br>Do not use this with single\_nat\_gateway=true and nat\_gateway\_enabled=true because all private subnets share one route table.<br><br>Example:<br>  additional\_private\_routes\_per\_subnet = {<br>    "eu-west-1a" = [<br>      {<br>        destination\_cidr\_block = "192.168.1.0/24"<br>        gateway\_id             = aws\_vpn\_gateway.this.id<br>      }<br>    ]<br>  } | `map(list(map(string)))` | `{}` | no |
| additional\_public\_routes\_for\_all | Routes added to EVERY public route table (all AZs get the same routes).<br>Use this when you want uniform routing across all AZs.<br><br>Example:<br>  additional\_public\_routes\_for\_all = [<br>    {<br>      destination\_cidr\_block = "10.100.0.0/16"<br>      gateway\_id             = aws\_vpn\_gateway.this.id<br>    }<br>  ] | `list(map(string))` | `[]` | no |
| additional\_public\_routes\_per\_subnet | Routes added to specific AZ public route tables only.<br>Key = AZ name or AZ ID, Value = list of routes for that AZ.<br>AZs not listed here get no additional per-subnet routes.<br><br>Example:<br>  additional\_public\_routes\_per\_subnet = {<br>    "eu-west-1a" = [<br>      {<br>        destination\_cidr\_block = "192.168.1.0/24"<br>        gateway\_id             = aws\_vpn\_gateway.this.id<br>      }<br>    ]<br>    "eu-west-1b" = [<br>      {<br>        destination\_cidr\_block = "192.168.2.0/24"<br>        transit\_gateway\_id     = aws\_ec2\_transit\_gateway.this.id<br>      }<br>    ]<br>  } | `map(list(map(string)))` | `{}` | no |
| attributes | Additional attributes (e.g. `1`). | `list(any)` | `[]` | no |
| availability\_zone\_ids | List of Availability Zone IDs (e.g. `use1-az1`, `use1-az2`). Use this instead of availability\_zones when consistent AZ mapping across AWS accounts is needed. | `list(string)` | `[]` | no |
| availability\_zones | List of Availability Zones (e.g. `['us-east-1a', 'us-east-1b', 'us-east-1c']`). | `list(string)` | `[]` | no |
| cidr\_block | Base IPv4 CIDR block divided into subnet CIDR blocks (e.g. `10.0.0.0/16`). Not used when IPv4 IPAM allocation is enabled or a subnet is IPv6-only. | `string` | `null` | no |
| delimiter | Delimiter to be used between `organization`, `environment`, `name` and `attributes`. | `string` | `"-"` | no |
| eigw\_id | Egress-Only Internet Gateway ID used for private subnet IPv6 default routes when enable\_ipv6 and enable\_eigw are true (e.g. `eigw-9c26a123`). | `string` | `null` | no |
| enable | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| enable\_eigw | Create a private IPv6 default route (`::/0`) targeting `eigw_id` in private route tables. Requires `enable_ipv6 = true` and `eigw_id`. | `bool` | `false` | no |
| enable\_flow\_log | Enable subnet\_flow\_log logs. | `bool` | `false` | no |
| enable\_ipv6 | Enable IPv6 CIDR assignment and subnet IPv6 settings. The VPC must already have an IPv6 CIDR block or an IPv6 IPAM pool must be configured. | `bool` | `false` | no |
| enable\_nat64 | Create a NAT64 IPv6 route (`64:ff9b::/96` by default) in private route tables targeting the NAT Gateway. Requires enable\_ipv6 = true and nat\_gateway\_enabled = true. | `bool` | `false` | no |
| enable\_private\_acl | Set to false to skip creating the private network ACL and its rules. | `bool` | `true` | no |
| enable\_public\_acl | Set to false to skip creating the public network ACL and its rules. | `bool` | `true` | no |
| environment | Environment (e.g. `prod`, `dev`, `staging`). | `string` | `""` | no |
| external\_nat\_ip\_ids | List of existing Elastic IP allocation IDs to attach to zonal public NAT Gateways when reuse\_nat\_ips is true. | `list(string)` | `[]` | no |
| extra\_private\_tags | Additional private subnet tags. | `map(any)` | `{}` | no |
| extra\_public\_tags | Additional public subnet tags. | `map(any)` | `{}` | no |
| flow\_log\_deliver\_cross\_account\_role | (Optional) ARN of the IAM role that allows Amazon EC2 to publish flow logs across accounts. | `string` | `null` | no |
| flow\_log\_destination\_arn | ARN of resource in which flow log will be sent. | `string` | `null` | no |
| flow\_log\_destination\_type | Type of flow log destination. Can be `cloud-watch-logs`, `s3`, or `kinesis-data-firehose`. | `string` | `"cloud-watch-logs"` | no |
| flow\_log\_file\_format | (Optional) The format for the flow log. Valid values: `plain-text`, `parquet` | `string` | `null` | no |
| flow\_log\_hive\_compatible\_partitions | (Optional) Indicates whether to use Hive-compatible prefixes for flow logs stored in Amazon S3 | `bool` | `false` | no |
| flow\_log\_iam\_role\_arn | The ARN for the IAM role that's used to post flow logs to a CloudWatch Logs log group. When flow\_log\_destination\_arn is set to ARN of Cloudwatch Logs, this argument needs to be provided | `string` | `null` | no |
| flow\_log\_log\_format | The fields to include in the flow log record, in the order in which they should appear | `string` | `null` | no |
| flow\_log\_max\_aggregation\_interval | The maximum interval of time during which a flow of packets is captured and aggregated into a flow log record. Valid Values: `60` seconds or `600` seconds | `number` | `600` | no |
| flow\_log\_per\_hour\_partition | (Optional) Indicates whether to partition the flow log per hour. This reduces the cost and response time for queries | `bool` | `false` | no |
| flow\_log\_tags | Additional tags for subnet flow logs. | `map(string)` | `{}` | no |
| flow\_log\_traffic\_type | Type of traffic to capture. Valid values: ACCEPT,REJECT, ALL. | `string` | `"ALL"` | no |
| igw\_id | Internet Gateway ID that is used as a default route when creating public subnets (e.g. `igw-9c26a123`). | `string` | `""` | no |
| ipv4\_ipam\_pool\_id | Optional IPv4 IPAM pool ID used to allocate subnet CIDRs. When set, ipv4\_netmask\_length is required and cidr\_block and explicit IPv4 subnet CIDR lists must be unset. | `string` | `null` | no |
| ipv4\_netmask\_length | IPv4 prefix length to request from ipv4\_ipam\_pool\_id. | `number` | `null` | no |
| ipv4\_private\_cidrs | Subnet CIDR blocks (e.g. `10.0.0.0/16`). | `list(any)` | `[]` | no |
| ipv4\_public\_cidrs | Subnet CIDR blocks (e.g. `10.0.0.0/16`). | `list(any)` | `[]` | no |
| ipv6\_cidr\_block | Base IPv6 CIDR block divided into /64 subnet CIDRs. Not used when IPv6 IPAM allocation is enabled. | `string` | `null` | no |
| ipv6\_ipam\_pool\_id | Optional IPv6 IPAM pool ID used to allocate subnet CIDRs when enable\_ipv6 is true. When set, ipv6\_netmask\_length is required and ipv6\_cidr\_block and explicit IPv6 subnet CIDR lists must be unset. | `string` | `null` | no |
| ipv6\_netmask\_length | IPv6 prefix length to request from ipv6\_ipam\_pool\_id (44–64 in increments of 4; must be 64 for IPv6-only subnets). | `number` | `null` | no |
| label\_order | Label order, e.g. `name`,`Environment`. | `list(any)` | <pre>[<br>  "name",<br>  "environment"<br>]</pre> | no |
| managedby | ManagedBy, eg 'CloudDrove'. | `string` | `"hello@clouddrove.com"` | no |
| map\_public\_ip\_on\_launch | Specify true to indicate that instances launched into the public subnet should be assigned a public IP address. | `bool` | `false` | no |
| name | Name  (e.g. `prod-subnet` or `subnet`). | `string` | `""` | no |
| nat64\_destination\_ipv6\_cidr\_block | Destination IPv6 CIDR block for the NAT64 route in private route tables. | `string` | `"64:ff9b::/96"` | no |
| nat\_eip\_tags | Additional tags for NAT Gateway Elastic IPs. | `map(string)` | `{}` | no |
| nat\_gateway\_availability\_mode | NAT Gateway availability mode (`zonal` or `regional`). `regional` creates a multi-AZ regional NAT Gateway attached directly to the VPC. | `string` | `"zonal"` | no |
| nat\_gateway\_connectivity\_type | NAT Gateway connectivity type. public (default) creates a standard NAT with EIP. private creates a private NAT (no EIP, routes between VPCs/on-prem). Valid values: public, private. | `string` | `"public"` | no |
| nat\_gateway\_destination\_cidr\_block | Used to pass a custom destination route for private NAT Gateway. If not specified, the default 0.0.0.0/0 is used as a destination route | `string` | `"0.0.0.0/0"` | no |
| nat\_gateway\_enabled | Flag to enable or disable NAT Gateway creation for private subnets. For zonal NAT Gateways, a public subnet or public\_subnet\_ids must be available for placement. | `bool` | `false` | no |
| nat\_gateway\_secondary\_private\_ip\_address\_count | Number of secondary private IPv4 addresses to assign to each zonal NAT Gateway. | `number` | `null` | no |
| nat\_gateway\_tags | Additional tags for NAT Gateways. | `map(string)` | `{}` | no |
| private\_acl\_tags | Additional tags for the private network ACL. | `map(string)` | `{}` | no |
| private\_inbound\_acl\_rules | Private subnets inbound network ACLs | `list(map(string))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 0,<br>    "protocol": "-1",<br>    "rule_action": "allow",<br>    "rule_number": 100,<br>    "to_port": 0<br>  }<br>]</pre> | no |
| private\_ipv6\_cidrs | Private Subnet CIDR blocks (e.g. `2a05:d018:832:ca02::/64`). | `list(any)` | `[]` | no |
| private\_outbound\_acl\_rules | Private subnets outbound network ACLs | `list(map(string))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 0,<br>    "protocol": "-1",<br>    "rule_action": "allow",<br>    "rule_number": 100,<br>    "to_port": 0<br>  }<br>]</pre> | no |
| private\_propagating\_vgws | List of Virtual Private Gateway IDs to propagate routes into private route tables. | `list(string)` | `[]` | no |
| private\_route\_table\_tags | Additional tags for private route tables. | `map(string)` | `{}` | no |
| private\_rt\_ipv6\_destination\_cidr | The destination IPv6 CIDR block for private route table egress-only internet gateway routes. | `string` | `"::/0"` | no |
| private\_subnet\_assign\_ipv6\_address\_on\_creation | Specify true to indicate that network interfaces created in the specified subnet should be assigned an IPv6 address. | `bool` | `false` | no |
| private\_subnet\_customer\_owned\_ipv4\_pool | Customer-owned IPv4 address pool (CoIP pool) ID for Outpost private subnets. Requires private\_subnet\_outpost\_arn. | `string` | `null` | no |
| private\_subnet\_enable\_dns64 | Indicates whether DNS queries made to the Amazon-provided DNS Resolver in this subnet should return synthetic IPv6 addresses for IPv4-only destinations. Default: `false` | `bool` | `false` | no |
| private\_subnet\_enable\_lni\_at\_device\_index | Device index (e.g. `1` for eth1) for Local Network Interfaces (LNIs) in Outpost private subnets. | `number` | `null` | no |
| private\_subnet\_enable\_resource\_name\_dns\_a\_record\_on\_launch | Indicates whether to respond to DNS queries for instance hostnames with DNS A records. Default: `false` | `bool` | `false` | no |
| private\_subnet\_enable\_resource\_name\_dns\_aaaa\_record\_on\_launch | Indicates whether to respond to DNS queries for instance hostnames with DNS AAAA records. Default: `false` | `bool` | `false` | no |
| private\_subnet\_ipv6\_native | Indicates whether to create an IPv6-only private subnet. Default: `false` | `bool` | `false` | no |
| private\_subnet\_map\_customer\_owned\_ip\_on\_launch | Assign a customer-owned IPv4 address on launch for Outpost private subnets. Requires private\_subnet\_outpost\_arn and private\_subnet\_customer\_owned\_ipv4\_pool. | `bool` | `false` | no |
| private\_subnet\_outpost\_arn | ARN of the AWS Outpost where private subnets should be created. | `string` | `null` | no |
| private\_subnet\_private\_dns\_hostname\_type\_on\_launch | The type of hostnames to assign to instances in the subnet at launch. For IPv6-only subnets, an instance DNS name must be based on the instance ID. For dual-stack and IPv4-only subnets, you can specify whether DNS names use the instance IPv4 address or the instance ID. Valid values: `ip-name`, `resource-name` | `string` | `null` | no |
| private\_subnet\_tags\_per\_az | Additional tags to merge onto private subnets keyed by Availability Zone name or AZ ID. | `map(map(string))` | `{}` | no |
| public\_acl\_tags | Additional tags for the public network ACL. | `map(string)` | `{}` | no |
| public\_inbound\_acl\_rules | Public subnets inbound network ACLs | `list(map(string))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 0,<br>    "protocol": "-1",<br>    "rule_action": "allow",<br>    "rule_number": 100,<br>    "to_port": 0<br>  }<br>]</pre> | no |
| public\_ipv6\_cidrs | Public Subnet CIDR blocks (e.g. `2a05:d018:832:ca02::/64`). | `list(any)` | `[]` | no |
| public\_outbound\_acl\_rules | Public subnets outbound network ACLs | `list(map(string))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 0,<br>    "protocol": "-1",<br>    "rule_action": "allow",<br>    "rule_number": 100,<br>    "to_port": 0<br>  }<br>]</pre> | no |
| public\_propagating\_vgws | List of Virtual Private Gateway IDs to propagate routes into public route tables. | `list(string)` | `[]` | no |
| public\_route\_table\_tags | Additional tags for public route tables. | `map(string)` | `{}` | no |
| public\_rt\_ipv4\_destination\_cidr | The destination ipv4 CIDR block. | `string` | `"0.0.0.0/0"` | no |
| public\_rt\_ipv6\_destination\_cidr | The destination ipv6 CIDR block. | `string` | `"::/0"` | no |
| public\_subnet\_assign\_ipv6\_address\_on\_creation | Specify true to indicate that network interfaces created in the specified subnet should be assigned an IPv6 address. | `bool` | `false` | no |
| public\_subnet\_customer\_owned\_ipv4\_pool | Customer-owned IPv4 address pool (CoIP pool) ID for Outpost public subnets. Requires public\_subnet\_outpost\_arn. | `string` | `null` | no |
| public\_subnet\_enable\_dns64 | Indicates whether DNS queries made to the Amazon-provided DNS Resolver in this subnet should return synthetic IPv6 addresses for IPv4-only destinations. Default: `false` | `bool` | `false` | no |
| public\_subnet\_enable\_lni\_at\_device\_index | Device index (e.g. `1` for eth1) for Local Network Interfaces (LNIs) in Outpost public subnets. | `number` | `null` | no |
| public\_subnet\_enable\_resource\_name\_dns\_a\_record\_on\_launch | Indicates whether to respond to DNS queries for instance hostnames with DNS A records. Default: `false` | `bool` | `false` | no |
| public\_subnet\_enable\_resource\_name\_dns\_aaaa\_record\_on\_launch | Indicates whether to respond to DNS queries for instance hostnames with DNS AAAA records. Default: `false` | `bool` | `false` | no |
| public\_subnet\_ids | A list of public subnet ids. | `list(string)` | `[]` | no |
| public\_subnet\_ipv6\_native | Indicates whether to create an IPv6-only public subnet. Default: `false` | `bool` | `false` | no |
| public\_subnet\_map\_customer\_owned\_ip\_on\_launch | Assign a customer-owned IPv4 address on launch for Outpost public subnets. Requires public\_subnet\_outpost\_arn and public\_subnet\_customer\_owned\_ipv4\_pool. | `bool` | `false` | no |
| public\_subnet\_outpost\_arn | ARN of the AWS Outpost where public subnets should be created. | `string` | `null` | no |
| public\_subnet\_private\_dns\_hostname\_type\_on\_launch | The type of hostnames to assign to instances in the subnet at launch. For IPv6-only subnets, an instance DNS name must be based on the instance ID. For dual-stack and IPv4-only subnets, you can specify whether DNS names use the instance IPv4 address or the instance ID. Valid values: `ip-name`, `resource-name` | `string` | `null` | no |
| public\_subnet\_tags\_per\_az | Additional tags to merge onto public subnets keyed by Availability Zone name or AZ ID. | `map(map(string))` | `{}` | no |
| region | AWS region where resources will be managed. Defaults to the region configured in the provider. | `string` | `null` | no |
| regional\_nat\_gateway\_address | Optional manual AZ-to-EIP mappings for a regional NAT Gateway (`availability_mode = regional`). Leave empty for AWS auto mode. | <pre>list(object({<br>    allocation_ids       = optional(list(string))<br>    availability_zone    = optional(string)<br>    availability_zone_id = optional(string)<br>  }))</pre> | `[]` | no |
| repository | Terraform current module repo | `string` | `"https://github.com/clouddrove/terraform-aws-subnet"` | no |
| reuse\_nat\_ips | Set to true to reuse existing Elastic IP allocation IDs supplied via external\_nat\_ip\_ids instead of creating new EIPs for zonal public NAT Gateways. | `bool` | `false` | no |
| single\_nat\_gateway | Create one NAT Gateway and share one private route table across AZs when nat\_gateway\_enabled is true. | `bool` | `false` | no |
| tags | Common tags applied to all resources created by this module. | `map(string)` | `{}` | no |
| type | Type of subnets to create (`private`, `public`, or `public-private`). | `string` | `""` | no |
| vpc\_id | VPC ID. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| nat\_eip\_allocation\_ids | Allocation IDs of module-created NAT Gateway Elastic IPs. |
| nat\_gateway\_ids | IDs of created NAT Gateways. |
| nat\_gateway\_private\_ip | Private IPv4 address of each NAT Gateway. |
| nat\_gateway\_public\_ip | Public IPv4 address of each NAT Gateway EIP. Whitelist these in external firewalls. |
| private\_acl | The ID of the network ACL. |
| private\_route\_tables\_id | The ID of the routing table. |
| private\_subnet\_arns | The ARNs of the created private subnets. |
| private\_subnet\_az\_ids | Availability Zone IDs of created private subnets, in the same order as private\_subnet\_id. |
| private\_subnet\_azs | Availability zones of created private subnets, in the same order as private\_subnet\_id. |
| private\_subnet\_cidrs | CIDR blocks of the created private subnets. |
| private\_subnet\_cidrs\_ipv6 | CIDR blocks of the created private subnets. |
| private\_subnet\_flow\_log\_ids | IDs of flow logs created for private subnets. |
| private\_subnet\_id | The ID of the private subnet. |
| private\_subnet\_ipv6\_cidr\_block\_association\_ids | IPv6 CIDR association IDs for the created private subnets. |
| private\_tags | A mapping of private tags to assign to the resource. |
| public\_acl | The ID of the network ACL. |
| public\_route\_tables\_id | The ID of the routing table. |
| public\_subnet\_arns | The ARNs of the created public subnets. |
| public\_subnet\_az\_ids | Availability Zone IDs of created public subnets, in the same order as public\_subnet\_id. |
| public\_subnet\_azs | Availability zones of created public subnets, in the same order as public\_subnet\_id. |
| public\_subnet\_cidrs | CIDR blocks of the created public subnets. |
| public\_subnet\_cidrs\_ipv6 | CIDR blocks of the created public subnets. |
| public\_subnet\_flow\_log\_ids | IDs of flow logs created for public subnets. |
| public\_subnet\_id | The ID of the subnet. |
| public\_subnet\_ipv6\_cidr\_block\_association\_ids | IPv6 CIDR association IDs for the created public subnets. |
| public\_tags | A mapping of public tags to assign to the resource. |
| regional\_nat\_gateway\_addresses | Per-AZ address details for regional NAT Gateways. |
