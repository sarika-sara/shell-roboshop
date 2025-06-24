#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
N="\e[0m"

log_folder="/var/log/roboshop-logs"
script_name=$(basename "$0")
log_file="$log_folder/$script_name.log"
LOG_FILE=$log_file  # Fixes empty LOG_FILE issue

mkdir -p $log_folder
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

# Check if the user has root privileges
if [ $USERID -eq 0 ]; then
  echo -e "${G}User has root access${N}" | tee -a $LOG_FILE
else
  echo -e "${R}User doesn't have root access${N}" | tee -a $LOG_FILE
  exit 1
fi

# Validate function
VALID() {
  if [ $1 -eq 0 ]; then
    echo -e "$G Installation of $2 is ....$G Successful$N"
  else
    echo -e "$R Installation of $2 is ....$R Failure$N"
    exit 1
  fi
}

# Start MongoDB setup
cp mongodb.repo /etc/yum.repos.d/mongodb.repo
VALID $? "copying MongoDB repo"

dnf install mongodb-org -y &>>$LOG_FILE
VALID $? "Installing mongodb server"

systemctl enable mongod &>>$LOG_FILE
VALID $? "Enabling MongoDB"

systemctl start mongod &>>$LOG_FILE
VALID $? "Starting MongoDB"

sed -i -e 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf
VALID $? "Editing MongoDB conf file for remote connections"

systemctl restart mongod &>>$LOG_FILE
VALID $? "Restarting MongoDB"