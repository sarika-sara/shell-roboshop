#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
N="\e[0m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "/" -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

if [ "$USERID" -ne 0 ]; then
  echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
  exit 1
else
  echo "You are running with root access" | tee -a $LOG_FILE
fi

VALIDATE(){
  if [ $1 -eq 0 ]; then
    echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
  else
    echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
    exit 1
  fi
}

# NodeJS setup
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling default nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling nodejs:20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing nodejs:20"

# Create roboshop user
id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
  VALIDATE $? "Creating roboshop system user"
else
  echo -e "$G User already exists $N" | tee -a $LOG_FILE
fi

# App directory
mkdir -p /app
VALIDATE $? "Creating app directory"
rm -rf /app/*

# Download & unzip catalogue
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading Catalogue"

cd /app
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Unzipping catalogue"

# Install node dependencies
npm install &>>$LOG_FILE
VALIDATE $? "Installing Dependencies"

# Setup catalogue service
cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_FILE
VALIDATE $? "Copying catalogue service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalogue &>>$LOG_FILE
systemctl start catalogue &>>$LOG_FILE
VALIDATE $? "Starting Catalogue"

# MongoDB Client & Schema setup
cp $SCRIPT_DIR/mongodb.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
VALIDATE $? "Copying repos"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installing MongoDB Client"

if [ -f /app/db/master-data.js ]; then
  mongosh "mongodb://mongodb.daws84s.life:27017/catalogue" < /app/db/master-data.js &>>$LOG_FILE
  VALIDATE $? "Loading MongoDB schema"
else
  echo -e "$R ERROR:: /app/db/master-data.js file not found. Check ZIP content. $N" | tee -a $LOG_FILE
  exit 1
fi
