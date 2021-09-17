# Using Terraform to deploy OpenVPN on AWS

Idea is to create a free vpn in any aws region. Typically you would sign up for a free AWS account, and use the free `t2.micro` instance and 15Gb monthly transfer limit. The aws free accounts last 12 months so when it expires, sign up for another and close the old one!

Unlike other terraform based deploys this does everything for you, including generating the client `.ovpn` file. You don't even need an Elastic IP (which will add to the cost).  Also this uses open source Openvpn rather than the AS or other commercial solutions. No resources are waisted on a web gui frontend (eg with the AS OpenVPN deploys) so you get more resources for the vpn on your low resource `t2.micro` instance.

This was designed to be a backup to my home OpenVPN server, which may become unavailable. Thus the need to be able to spin up an alternative at short notice and tear it down when not using it. You could also shut down the ec2 instance to save compute hours. It takes about a minute to deploy or destroy.

This was developed with terraform 0.15/1.0.

Credit to [angristan/openvpn-install](https://github.com/angristan/openvpn-install) for his OpenVPN install script that makes the install and client setup easy.

# Deploying. destroying, AWS Region, etc

The context defines the aws region, credentials, etc; see [offical aws docs](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) for this. Also its kind of messy to include region and credentials code in your terraform when you can just define it in the context; often a pitfall for those new to aws. Here is how to manage your context and multiple aws accounts (assuming Linux):
```
$ env|grep AWS
AWS_PROFILE=aws7-admin1
AWS_DEFAULT_REGION=eu-west-1
AWS_REGION=eu-west-1
```

## Deploying

I suggest you use the supplied script `apply-generate-ovpn.sh`; this will do the following:
* Use terraform workspaces if the `AWS_REGION` env var is specified (see example) so you can deploy multiple vpn's into different regions.
* Perform `terraform apply` with `auto-approve` (no confirmation).
* Wait for the client ovpn to appear in the AWS Systems Manager parameter store.
* Generate the `.ovpn` file for you, ready to load into your vpn client.

Here is an example run:
```
$ AWS_REGION=eu-west-2 ./apply-generate-ovpn.sh 
Setting terraform workspace to eu-west-2...
Switched to workspace "eu-west-2".
Performing terraform apply...

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_iam_instance_profile.ovpn will be created
  + resource "aws_iam_instance_profile" "ovpn" {
      + arn         = (known after apply)
      + create_date = (known after apply)
      + id          = (known after apply)
      + name        = "openvpn"
      + path        = "/"
      + role        = "openvpn"
      + tags_all    = (known after apply)
      + unique_id   = (known after apply)
    }

  # aws_iam_policy.ovpn will be created
  + resource "aws_iam_policy" "ovpn" {
      + arn       = (known after apply)
      + id        = (known after apply)
      + name      = "openvpn"
      + path      = "/"
      + policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action   = [
                          + "ssm:PutParameter",
                        ]
                      + Effect   = "Allow"
                      + Resource = [
                          + "*",
                        ]
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + policy_id = (known after apply)
      + tags_all  = (known after apply)
    }

  # aws_iam_role.ovpn will be created
  + resource "aws_iam_role" "ovpn" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "sts:AssumeRole"
                      + Effect    = "Allow"
                      + Principal = {
                          + Service = "ec2.amazonaws.com"
                        }
                      + Sid       = ""
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + force_detach_policies = false
      + id                    = (known after apply)
      + managed_policy_arns   = (known after apply)
      + max_session_duration  = 3600
      + name                  = "openvpn"
      + path                  = "/"
      + tags_all              = (known after apply)
      + unique_id             = (known after apply)

      + inline_policy {
          + name   = (known after apply)
          + policy = (known after apply)
        }
    }

  # aws_iam_role_policy_attachment.ovpn will be created
  + resource "aws_iam_role_policy_attachment" "ovpn" {
      + id         = (known after apply)
      + policy_arn = (known after apply)
      + role       = "openvpn"
    }

  # aws_instance.ovpn will be created
  + resource "aws_instance" "ovpn" {
      + ami                                  = "ami-093d303510c432519"
      + arn                                  = (known after apply)
      + associate_public_ip_address          = (known after apply)
      + availability_zone                    = (known after apply)
      + cpu_core_count                       = (known after apply)
      + cpu_threads_per_core                 = (known after apply)
      + get_password_data                    = false
      + host_id                              = (known after apply)
      + iam_instance_profile                 = "openvpn"
      + id                                   = (known after apply)
      + instance_initiated_shutdown_behavior = (known after apply)
      + instance_state                       = (known after apply)
      + instance_type                        = "t2.micro"
      + ipv6_address_count                   = (known after apply)
      + ipv6_addresses                       = (known after apply)
      + key_name                             = (known after apply)
      + outpost_arn                          = (known after apply)
      + password_data                        = (known after apply)
      + placement_group                      = (known after apply)
      + primary_network_interface_id         = (known after apply)
      + private_dns                          = (known after apply)
      + private_ip                           = (known after apply)
      + public_dns                           = (known after apply)
      + public_ip                            = (known after apply)
      + secondary_private_ips                = (known after apply)
      + security_groups                      = (known after apply)
      + source_dest_check                    = true
      + subnet_id                            = (known after apply)
      + tags                                 = {
          + "Name" = "openvpn"
        }
      + tags_all                             = {
          + "Name" = "openvpn"
        }
      + tenancy                              = (known after apply)
      + user_data                            = "4db7916ef4c426d4947acd0101d9616858a254c5"
      + vpc_security_group_ids               = (known after apply)

      + capacity_reservation_specification {
          + capacity_reservation_preference = (known after apply)

          + capacity_reservation_target {
              + capacity_reservation_id = (known after apply)
            }
        }

      + ebs_block_device {
          + delete_on_termination = (known after apply)
          + device_name           = (known after apply)
          + encrypted             = (known after apply)
          + iops                  = (known after apply)
          + kms_key_id            = (known after apply)
          + snapshot_id           = (known after apply)
          + tags                  = (known after apply)
          + throughput            = (known after apply)
          + volume_id             = (known after apply)
          + volume_size           = (known after apply)
          + volume_type           = (known after apply)
        }

      + enclave_options {
          + enabled = (known after apply)
        }

      + ephemeral_block_device {
          + device_name  = (known after apply)
          + no_device    = (known after apply)
          + virtual_name = (known after apply)
        }

      + metadata_options {
          + http_endpoint               = (known after apply)
          + http_put_response_hop_limit = (known after apply)
          + http_tokens                 = (known after apply)
        }

      + network_interface {
          + delete_on_termination = (known after apply)
          + device_index          = (known after apply)
          + network_interface_id  = (known after apply)
        }

      + root_block_device {
          + delete_on_termination = (known after apply)
          + device_name           = (known after apply)
          + encrypted             = (known after apply)
          + iops                  = (known after apply)
          + kms_key_id            = (known after apply)
          + tags                  = (known after apply)
          + throughput            = (known after apply)
          + volume_id             = (known after apply)
          + volume_size           = (known after apply)
          + volume_type           = (known after apply)
        }
    }

  # aws_security_group.ovpn will be created
  + resource "aws_security_group" "ovpn" {
      + arn                    = (known after apply)
      + description            = "OpenVPN security group"
      + egress                 = [
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = ""
              + from_port        = 0
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "-1"
              + security_groups  = []
              + self             = false
              + to_port          = 0
            },
        ]
      + id                     = (known after apply)
      + ingress                = [
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = ""
              + from_port        = 1194
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "udp"
              + security_groups  = []
              + self             = false
              + to_port          = 1194
            },
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = ""
              + from_port        = 22
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "tcp"
              + security_groups  = []
              + self             = false
              + to_port          = 22
            },
        ]
      + name                   = "openvpn"
      + name_prefix            = (known after apply)
      + owner_id               = (known after apply)
      + revoke_rules_on_delete = false
      + tags_all               = (known after apply)
      + vpc_id                 = (known after apply)
    }

  # aws_ssm_parameter.ovpn will be created
  + resource "aws_ssm_parameter" "ovpn" {
      + arn       = (known after apply)
      + data_type = (known after apply)
      + id        = (known after apply)
      + key_id    = (known after apply)
      + name      = "/openvpn/clients/london.ovpn"
      + tags_all  = (known after apply)
      + tier      = "Standard"
      + type      = "String"
      + value     = (sensitive value)
      + version   = (known after apply)
    }

Plan: 7 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + ovpn_file                = "london.ovpn"
  + ovpn_ssm_parameter_name  = "/openvpn/clients/london.ovpn"
  + ovpn_ssm_parameter_value = (sensitive value)
  + public_ip                = (known after apply)
aws_iam_role.ovpn: Creating...
aws_iam_policy.ovpn: Creating...
aws_ssm_parameter.ovpn: Creating...
aws_security_group.ovpn: Creating...
aws_iam_policy.ovpn: Creation complete after 4s [id=arn:aws:iam::578696731580:policy/openvpn]
aws_ssm_parameter.ovpn: Creation complete after 5s [id=/openvpn/clients/london.ovpn]
aws_iam_role.ovpn: Creation complete after 5s [id=openvpn]
aws_iam_role_policy_attachment.ovpn: Creating...
aws_iam_instance_profile.ovpn: Creating...
aws_iam_role_policy_attachment.ovpn: Creation complete after 3s [id=openvpn-20210627081023612600000001]
aws_security_group.ovpn: Creation complete after 8s [id=sg-0703553365916606b]
aws_iam_instance_profile.ovpn: Creation complete after 4s [id=openvpn]
aws_instance.ovpn: Creating...
aws_instance.ovpn: Still creating... [10s elapsed]
aws_instance.ovpn: Still creating... [20s elapsed]
aws_instance.ovpn: Still creating... [30s elapsed]
aws_instance.ovpn: Still creating... [40s elapsed]
aws_instance.ovpn: Creation complete after 47s [id=i-0a3d6e2c78a39639e]

Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:

ovpn_file = "london.ovpn"
ovpn_ssm_parameter_name = "/openvpn/clients/london.ovpn"
ovpn_ssm_parameter_value = <sensitive>
public_ip = "3.10.205.244"
Waiting for ovpn client config to be created...
Refreshing terraform outputs...
Refreshing terraform outputs...
Refreshing terraform outputs...
Refreshing terraform outputs...
Refreshing terraform outputs...
OpenVPN client config has been written to file "london.ovpn". Use this with your vpn client.
```

If you wish to ssh to the ec2 instance and debug the setup you can deploy the terraform manually with an existing key pair:
```
AWS_REGION=eu-west-2 terraform apply -auto-approve -var key_pair=aws7-london
```

## Destroying

Make sure you are disconnected from the vpn first!!!

To destroy the deploy example in the last section:
```
AWS_REGION=eu-west-2 terraform destroy -auto-approve
```

# Using the ovpn client configuration

My understanding is the OpenVPN client config file type is `.ovpn` (well it been called that since I setup my home OpenVPN server many years back). Thus you simply install the `.ovpn` file generated by the `apply-generate-ovpn.sh` script into your vpn client (I do this on Andriod and Linux and it works fine). For the example above the file generated is `london.ovpn`.

I mainly used Linux Mint (Debian based) and network manager, so will describe this setup:
* Click on the network icon on your task bar.
* Select `Network connections` on the bottom.
* Click on `+` at the bottom LH of the pop up box.
* Scroll through the `Connection Types` until you come across `Import a saved VPN connection`. Click on `Create`.
* Browse and select your `.ovpn` file and click on `Open`.
* Edit the connect as required.
* Click on `Save`.
* Then click on the network icon again and select your vpn connection you just added. The network icon will change to a padlock.
* Open a web browser and Google `whatsmyip`. Choose one of the links that show you where the IP is located in the world. 
* Check you location is correct.

# Jenkins pipeline

I have provided a Jenkins pipeline that you can use in your Jenkins to deploy/destroy the vpn.

The state is held in the Jenkins workspace.

You can run it multiple times for different regions, and terraform uses workspaces for the different regions.

You have the option to specify create/destroy, the region and jenkins aws credential as parameters.

The ovpn client config will be displayed on the Job console output; cut and paste this into you Openvpn client.

You should add `terraform` as a Tool in Jenkins and label it as the `terraform` version. Some instructions [here](
) (or Google for better instructions if these are insufficient).

# Possible improvements

* You could generate multiple client `.ovpn` files per region (eg `london-0.ovpn` etc). This would involve running the userdata script `openvpn-install.sh` multiple times for clients > 1, and then setting up multiple Systems Manager parameters. For my needs I just need the single ovpn file. If you decide to do this, raise a PR so I can merge it in.
