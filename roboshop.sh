#!/bin/bash
AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-06ac706b2ca290189"
INSTANCE_TYPE=("mongodb" "redis" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")
ZONE_ID="Z05650453EAGV8BJNVHGB"
DOMAIN_NAME="daws84s.life"

for instance in "${INSTANCE_TYPE[@]}"
do
   Instance_ID=$(aws ec2 run-instances --image-id $AMI_ID  --instance-type t3.micro  --security-group-ids $SG_ID     --tag-specifications  "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]"  --query "Instances[0].InstanceId"     --output text)
  if [ $instance != "frontend" ]
    then
        IP=$(aws ec2 describe-instances --instance-ids $Instance_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
    else
    IP=$(aws ec2 describe-instances --instance-ids $Instance_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
    fi
            echo "$instance IP address: $IP"
            aws route53 change-resource-record-sets \
   --hosted-zone-id $ZONE_ID \
   --change-batch '
{
    "Comment": "Update record to add new A record",
    "Changes": 
    [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": 
            {
                "Name": "'$instance'.'$DOMAIN_NAME'",
                "Type": "A",
                "TTL": 1,
                "ResourceRecords": 
                [
                    {
                        "Value": "'$IP'"
                    }
                ]
            }
        }
    ]
}'
   done
