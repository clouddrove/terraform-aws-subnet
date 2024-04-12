## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| attributes | Additional attributes (e.g. `1`). | `list(any)` | `[]` | no |
| availability\_zones | List of Availability Zones (e.g. `['us-east-1a', 'us-east-1b', 'us-east-1c']`). | `list(string)` | `[]` | no |
| cidr\_block | Base CIDR block which is divided into subnet CIDR blocks (e.g. `10.0.0.0/16`). | `string` | `null` | no |
| delimiter | Delimiter to be used between `organization`, `environment`, `name` and `attributes`. | `string` | `"-"` | no |
| enable | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| enable\_flow\_log | Enable subnet\_flow\_log logs. | `bool` | `false` | no |
| enable\_ipv6 | Requests an Amazon-provided IPv6 CIDR block with a /56 prefix length for the VPC. You cannot specify the range of IP addresses, or the size of the CIDR block | `bool` | `false` | no |
| enable\_private\_acl | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| enable\_public\_acl | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| environment | Environment (e.g. `prod`, `dev`, `staging`). | `string` | `""` | no |
| extra\_private\_tags | Additional private subnet tags. | `map(any)` | `{}` | no |
| extra\_public\_tags | Additional public subnet tags. | `map(any)` | `{}` | no |
| flow\_log\_destination\_arn | ARN of resource in which flow log will be sent. | `string` | `null` | no |
| flow\_log\_destination\_type | Type of flow log destination. Can be s3 or cloud-watch-logs | `string` | `"cloud-watch-logs"` | no |
| flow\_log\_file\_format | (Optional) The format for the flow log. Valid values: `plain-text`, `parquet` | `string` | `null` | no |
| flow\_log\_hive\_compatible\_partitions | (Optional) Indicates whether to use Hive-compatible prefixes for flow logs stored in Amazon S3 | `bool` | `false` | no |
| flow\_log\_iam\_role\_arn | The ARN for the IAM role that's used to post flow logs to a CloudWatch Logs log group. When flow\_log\_destination\_arn is set to ARN of Cloudwatch Logs, this argument needs to be provided | `string` | `null` | no |
| flow\_log\_log\_format | The fields to include in the flow log record, in the order in which they should appear | `string` | `null` | no |
| flow\_log\_max\_aggregation\_interval | The maximum interval of time during which a flow of packets is captured and aggregated into a flow log record. Valid Values: `60` seconds or `600` seconds | `number` | `600` | no |
| flow\_log\_per\_hour\_partition | (Optional) Indicates whether to partition the flow log per hour. This reduces the cost and response time for queries | `bool` | `false` | no |
| flow\_log\_traffic\_type | Type of traffic to capture. Valid values: ACCEPT,REJECT, ALL. | `string` | `"ALL"` | no |
| igw\_id | Internet Gateway ID that is used as a default route when creating public subnets (e.g. `igw-9c26a123`). | `string` | `""` | no |
| ipv4\_private\_cidrs | Subnet CIDR blocks (e.g. `10.0.0.0/16`). | `list(any)` | `[]` | no |
| ipv4\_public\_cidrs | Subnet CIDR blocks (e.g. `10.0.0.0/16`). | `list(any)` | `[]` | no |
| ipv6\_cidr\_block | Base CIDR block which is divided into subnet CIDR blocks (e.g. `10.0.0.0/16`). | `string` | `null` | no |
| label\_order | Label order, e.g. `name`,`Environment`. | `list(any)` | <pre>[<br>  "name",<br>  "environment"<br>]</pre> | no |
| managedby | ManagedBy, eg 'CloudDrove'. | `string` | `"hello@clouddrove.com"` | no |
| map\_public\_ip\_on\_launch | Specify true to indicate that instances launched into the public subnet should be assigned a public IP address. | `bool` | `false` | no |
| name | Name  (e.g. `prod-subnet` or `subnet`). | `string` | `""` | no |
| nat\_gateway\_destination\_cidr\_block | Used to pass a custom destination route for private NAT Gateway. If not specified, the default 0.0.0.0/0 is used as a destination route | `string` | `"0.0.0.0/0"` | no |
| nat\_gateway\_enabled | Flag to enable/disable NAT Gateways creation in public subnets. | `bool` | `false` | no |
| private\_inbound\_acl\_rules | Private subnets inbound network ACLs | `list(map(string))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 0,<br>    "protocol": "-1",<br>    "rule_action": "deny",<br>    "rule_number": 100,<br>    "to_port": 0<br>  }<br>]</pre> | no |
| private\_ipv6\_cidrs | Private Subnet CIDR blocks (e.g. `2a05:d018:832:ca02::/64`). | `list(any)` | `[]` | no |
| private\_outbound\_acl\_rules | Private subnets outbound network ACLs | `list(map(string))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 0,<br>    "protocol": "-1",<br>    "rule_action": "deny",<br>    "rule_number": 100,<br>    "to_port": 0<br>  }<br>]</pre> | no |
| private\_subnet\_assign\_ipv6\_address\_on\_creation | Specify true to indicate that network interfaces created in the specified subnet should be assigned an IPv6 address. | `bool` | `false` | no |
| private\_subnet\_enable\_dns64 | Indicates whether DNS queries made to the Amazon-provided DNS Resolver in this subnet should return synthetic IPv6 addresses for IPv4-only destinations. Default: `true` | `bool` | `false` | no |
| private\_subnet\_enable\_resource\_name\_dns\_a\_record\_on\_launch | Indicates whether to respond to DNS queries for instance hostnames with DNS A records. Default: `false` | `bool` | `false` | no |
| private\_subnet\_enable\_resource\_name\_dns\_aaaa\_record\_on\_launch | Indicates whether to respond to DNS queries for instance hostnames with DNS AAAA records. Default: `true` | `bool` | `false` | no |
| private\_subnet\_ipv6\_native | Indicates whether to create an IPv6-only private subnet. Default: `false` | `bool` | `false` | no |
| private\_subnet\_private\_dns\_hostname\_type\_on\_launch | The type of hostnames to assign to instances in the subnet at launch. For IPv6-only subnets, an instance DNS name must be based on the instance ID. For dual-stack and IPv4-only subnets, you can specify whether DNS names use the instance IPv4 address or the instance ID. Valid values: `ip-name`, `resource-name` | `string` | `null` | no |
| public\_inbound\_acl\_rules | Public subnets inbound network ACLs | `list(map(string))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 0,<br>    "protocol": "-1",<br>    "rule_action": "allow",<br>    "rule_number": 100,<br>    "to_port": 0<br>  }<br>]</pre> | no |
| public\_ipv6\_cidrs | Public Subnet CIDR blocks (e.g. `2a05:d018:832:ca02::/64`). | `list(any)` | `[]` | no |
| public\_outbound\_acl\_rules | Public subnets outbound network ACLs | `list(map(string))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 0,<br>    "protocol": "-1",<br>    "rule_action": "allow",<br>    "rule_number": 100,<br>    "to_port": 0<br>  }<br>]</pre> | no |
| public\_rt\_ipv4\_destination\_cidr | The destination ipv4 CIDR block. | `string` | `"0.0.0.0/0"` | no |
| public\_rt\_ipv6\_destination\_cidr | The destination ipv6 CIDR block. | `string` | `"::/0"` | no |
| public\_subnet\_assign\_ipv6\_address\_on\_creation | Specify true to indicate that network interfaces created in the specified subnet should be assigned an IPv6 address. | `bool` | `false` | no |
| public\_subnet\_enable\_dns64 | Indicates whether DNS queries made to the Amazon-provided DNS Resolver in this subnet should return synthetic IPv6 addresses for IPv4-only destinations. Default: `true` | `bool` | `false` | no |
| public\_subnet\_enable\_resource\_name\_dns\_a\_record\_on\_launch | Indicates whether to respond to DNS queries for instance hostnames with DNS A records. Default: `false` | `bool` | `false` | no |
| public\_subnet\_enable\_resource\_name\_dns\_aaaa\_record\_on\_launch | Indicates whether to respond to DNS queries for instance hostnames with DNS AAAA records. Default: `true` | `bool` | `false` | no |
| public\_subnet\_ids | A list of public subnet ids. | `list(string)` | `[]` | no |
| public\_subnet\_ipv6\_native | Indicates whether to create an IPv6-only public subnet. Default: `false` | `bool` | `false` | no |
| public\_subnet\_private\_dns\_hostname\_type\_on\_launch | The type of hostnames to assign to instances in the subnet at launch. For IPv6-only subnets, an instance DNS name must be based on the instance ID. For dual-stack and IPv4-only subnets, you can specify whether DNS names use the instance IPv4 address or the instance ID. Valid values: `ip-name`, `resource-name` | `string` | `null` | no |
| repository | Terraform current module repo | `string` | `"https://github.com/clouddrove/terraform-aws-subnet"` | no |
| single\_nat\_gateway | Enable for only single NAT Gateway in one Availability Zone | `bool` | `false` | no |
| type | Type of subnets to create (`private` or `public`). | `string` | `""` | no |
| vpc\_id | VPC ID. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| nat\_gateway\_private\_ip | The private IPv4 address to assign to the NAT Gateway. If you don't provide an address, a private IPv4 address will be automatically assigned. |
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

