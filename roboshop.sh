#!?bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-06ac706b2ca290189"
INSTANCE_TYPE=("mongodb" "redis" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")
ZONE_ID="Z05650453EAGV8BJNVHGB"
DOMAIN_NAME="daws84s.life"

for instance in ${INSTANCES[@]}
do
   Instance_ID=$(aws ec2 run-instances  
     --image-id ami-09c813fb71547fc4f /
     --instance-type t2.micro /
     --security-group-ids sg-06ac706b2ca290189 /
     --tag-specifications  "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]"--query "Instances[0].InstanceId" /
     --output text)
  if[ $instance != "frontend" ]
    then
        IP=aws ec2 describe-instances --instance-ids $Instance_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text
else
    IP=aws ec2 describe-instances --instance-ids $Instance_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text
    fi
            echo "$instance IP address: $IP"
done