# Using Terraform to deploy OpenVPN on AWS

Idea behind this is to create an almost free vpn in any aws region. Typically you would sign up for a free AWS account, and use the free `t2.micro` instance and 15Gb monthly transfer limit.

Unlike other terraform based deploys this does everything for you, including generating the client ovpn file. You don't even need an Elastic IP (which will add to the cost).

Also unlike other terraform deploys, this uses purely open source Openvpn. No resources are waisted on a web gui frontend so you get more resources for the vpn on your low resource `t2.micro` instance.

This is ultimatly designed to run as a Jenkins pipeline so I can spin up a VPN whenever I want, and then tear it down when done, thus not consuming the AWS Free Tier resources. It takes about a minute to deploy, so if fired from a Jenkins job thats pretty reasonable.

This was developed with terraform 0.15/1.0.

Credit to [angristan/openvpn-install](https://github.com/angristan/openvpn-install) for his install script that make the OpenVPN install and client setup a breeze.

# AWS Region

Thus the context defines the aws region. Also its kind of messy to include region code in your terraform when you can just define it in the context; often a pitfall of someone new to aws. Here is how to manage your context and multiple aws accounts:
```
$ env|grep AWS
AWS_PROFILE=aws7-admin1
AWS_DEFAULT_REGION=eu-west-1
AWS_REGION=eu-west-1
```

It can also be done this way overriding your env vars:
```
AWS_REGION=eu-west-2 terraform plan
```

# Terraform variables

You don't need to pass any variables if you never intend to ssh to the EC2 instance. Otherwise you can set variable `key_pair` to an already provisioned key pair. The only thing you need to do is set you AWS region so the VPN is setup in the correct region/country.
You can pass these on the command line using multiple args; eg `-var foo=bar`.

Variables:
* password - openvpn password. Default: generated string.
* username - openvpn username. Default `openvpn`.
* key_pair - ec2 keypair to use. Default: no key pair (cannot ssh to the instance).

# Getting the ovpn client configuration

This is stored as a Systems Manager Parameter, which is then presented as a terraform output. Thus you can either cut and paste it from SM Parameter Store or get it from the outputs. The terraform sets the value to an initial value ("Not populated yet."), which is then properly populated by the userdata of the ec2 instance; you will probably need to do a `terraform refresh` to get its updated value.

The terraform output is hidden by default if you do a `terraform output`; instead you need to explictly specify the variable; eg `terraform output ovpn_ssm_parameter_value`.

```
$ AWS_REGION=eu-west-2 terraform output
ovpn_ssm_parameter_name = "/openvpn/client-ovpn/london.ovpn"
ovpn_ssm_parameter_value = <sensitive>
public_ip = "18.134.6.172"
```

Example of the `terraform refresh`:
```
$ AWS_REGION=eu-west-2 terraform output ovpn_ssm_parameter_value
"Not populated yet."

$ AWS_REGION=eu-west-2 terraform refresh
aws_iam_policy.ovpn: Refreshing state... [id=arn:aws:iam::578696731580:policy/openvpn]
aws_iam_role.ovpn: Refreshing state... [id=openvpn]
aws_security_group.ovpn: Refreshing state... [id=sg-053e1f90bae98c0c2]
aws_ssm_parameter.ovpn: Refreshing state... [id=/openvpn/client-ovpn/london.ovpn]
aws_iam_role_policy_attachment.ovpn: Refreshing state... [id=openvpn-20210625115623943900000001]
aws_iam_instance_profile.ovpn: Refreshing state... [id=openvpn]
aws_instance.ovpn: Refreshing state... [id=i-057c7a33922762569]

Outputs:

ovpn_ssm_parameter_name = "/openvpn/client-ovpn/london.ovpn"
ovpn_ssm_parameter_value = <sensitive>
public_ip = "18.134.6.172"

$ AWS_REGION=eu-west-2 terraform output -raw ovpn_ssm_parameter_value
client
proto udp
explicit-exit-notify
remote 18.134.6.172 1194
dev tun
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
verify-x509-name server_D20H0JrIEKod6e0s name
auth SHA256
auth-nocache
cipher AES-128-GCM
tls-client
tls-version-min 1.2
tls-cipher TLS-ECDHE-ECDSA-WITH-AES-128-GCM-SHA256
ignore-unknown-option block-outside-dns
setenv opt block-outside-dns # Prevent Windows 10 DNS leak
verb 3
<ca>
-----BEGIN CERTIFICATE-----
MIIB1zCCAX2gAwIBAgIUH4OIDOyZgBodQlgXL3gkjuhApW8wCgYIKoZIzj0EAwIw
HjEcMBoGA1UEAwwTY25fTlV2eUFMUThjZlJEOXgxTTAeFw0yMTA2MjUxMTU5MDZa
Fw0zMTA2MjMxMTU5MDZaMB4xHDAaBgNVBAMME2NuX05VdnlBTFE4Y2ZSRDl4MU0w
WTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAATGlf+YYX1T06jSHePhDQQ2V/yk+Wqk
9RPQEu8wd/UK8l55tIhYKzFg9rbcaJx2XERA1XUNUmNUv2z7/TXXdnfno4GYMIGV
MB0GA1UdDgQWBBQivuhango2O7eGyUnthj3wQrCMqjBZBgNVHSMEUjBQgBQivuha
ngo2O7eGyUnthj3wQrCMqqEipCAwHjEcMBoGA1UEAwwTY25fTlV2eUFMUThjZlJE
OXgxTYIUH4OIDOyZgBodQlgXL3gkjuhApW8wDAYDVR0TBAUwAwEB/zALBgNVHQ8E
BAMCAQYwCgYIKoZIzj0EAwIDSAAwRQIgW7NARvz74qiI5yVgiohyP8I85bUjohOw
AWv0rHgYo4ACIQDJojKxwM5MKxLgjDVY5kDvGN+Xfh/WvWwM3i2pYvw1rw==
-----END CERTIFICATE-----
</ca>
<cert>
-----BEGIN CERTIFICATE-----
MIIB2jCCAX+gAwIBAgIRAJAk2Mq/Spd1KgdkPs0WncgwCgYIKoZIzj0EAwIwHjEc
MBoGA1UEAwwTY25fTlV2eUFMUThjZlJEOXgxTTAeFw0yMTA2MjUxMTU5MDhaFw0y
MzA5MjgxMTU5MDhaMBExDzANBgNVBAMMBmxvbmRvbjBZMBMGByqGSM49AgEGCCqG
SM49AwEHA0IABAj/JDRetg4Q2TeWDtlXceYuBCyMdLOquS/NXm2Hnou28nyBzMyc
IvJjkpZ4TgBwEETjSPByYPh2duE1CPp4CHujgaowgacwCQYDVR0TBAIwADAdBgNV
HQ4EFgQU3T0u8G8Feorl3xLznMWvDlvdGH4wWQYDVR0jBFIwUIAUIr7oWp4KNju3
hslJ7YY98EKwjKqhIqQgMB4xHDAaBgNVBAMME2NuX05VdnlBTFE4Y2ZSRDl4MU2C
FB+DiAzsmYAaHUJYFy94JI7oQKVvMBMGA1UdJQQMMAoGCCsGAQUFBwMCMAsGA1Ud
DwQEAwIHgDAKBggqhkjOPQQDAgNJADBGAiEA93UAx47LC0FuxmLIkPbZ6qCBtC3T
xQ78Ap9nF6dURG0CIQDvEK4zvoql9k07ZKL/hYcnYDXnblWm/3O6xR1epIaA9A==
-----END CERTIFICATE-----
</cert>
<key>
-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgFTHUfj3q98Peo+/S
c3J30u7kIrHbu4JMplS0Z9XAaQGhRANCAAQI/yQ0XrYOENk3lg7ZV3HmLgQsjHSz
qrkvzV5th56LtvJ8gczMnCLyY5KWeE4AcBBE40jwcmD4dnbhNQj6eAh7
-----END PRIVATE KEY-----
</key>
<tls-crypt>
#
# 2048 bit OpenVPN static key
#
-----BEGIN OpenVPN Static key V1-----
3ca790efbe0f87c04c88f265fc54ffb0
a21bb8640de856c7e66b9f871e73939e
f2097238d9c879f788791e4d6101dc50
5800e9877147862baaa26e64c49cb4a5
ee0f76256251a10802f926f9daf91cb0
6e67acc968608f708b2e813278126a0b
f41d478e962f104a0ceb56fb84ef7a59
668801920d750ec31c13b80752394b62
dcc3aa10db1fe0099c0011e3521b2216
fa4a8eb045cd64d9da87d7aa0ffb4dcf
90a061ca7eca18e7b76494b544a53944
317a5b8b3a33b18ac8e806ba4e91f2a5
55e2eba316d61e1ce456e6f072a11c8d
832b1bc7034cf5dae84bafcb9ae85b68
2ed1a7e19c01ce0857a48933b263c3d5
2ebeabbda627deb6a22f13bedd4ab7a0
-----END OpenVPN Static key V1-----
</tls-crypt>
```

# Using the ovpn client configuration

My understanding is the OpenVPN client config file is of type `.ovpn` (well it been called that since I setup my home OpenVPN server many years back). Thus you simple cut and paste the output of the terraform output to a file (or direct it output if using Linux). Then install it on an Openvpn client (I do this on Andriod and it works fine). For the example above I would call the file `london.ovpn`.

I mainly used Linux Mint (Debian based) and network manager, so will describe this setup:
* Click on the network icon on your task bar.
* Select Network connections on the bottom.
* Click on + at the bottom LH of the pop up box.
* Scroll through the Connection Types until you come across Import a saved VPN connection... Click on that.
* Click om Create.
* Browse and Open your .ovpn file.
* Edit the connect as required.
* Click on Save.
* Then click on the network icon again and select your vpn connection you just added. The network icon will change to a padlock.
* Open a web browser and Google whatsmyip. Check you location is correct.

