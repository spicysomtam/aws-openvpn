#!/bin/bash

f=0 # found
p="ovpn_ssm_parameter_value"

# Use tf workspaces if AWS_REGION defined so we can have multiple vpn's in different regions
[ "$AWS_REGION" ] && {
  echo "Setting terraform workspace to $AWS_REGION..."
  terraform workspace new $AWS_REGION > /dev/null 2>&1
  terraform workspace select $AWS_REGION
}

echo "Performing terraform apply..."
terraform apply -auto-approve

echo "Waiting for ovpn client config to be created..."
while [ $f -eq 0 ]
do
  o=$(terraform output -raw $p)

  if [ "$o" == "Not populated yet." ]
  then
    sleep 5
    echo "Refreshing terraform outputs..."
    terraform refresh > /dev/null
  else
    of=$(terraform output -raw ovpn_file)
    if [ $1 = "display-ovpn" ]
    then
      echo "Ovpn file (\"${of}\"); use this with your client:"
      echo "==============================================================================================================================="
      terraform output -raw $p
      echo ""
      echo "==============================================================================================================================="
    else
      echo "OpenVPN client config has been written to file \"${of}\". Use this with your vpn client."
      terraform output -raw $p > $of
    fi
    f=1
    break
  fi
done
