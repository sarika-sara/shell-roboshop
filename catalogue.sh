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

# Install NodeJS
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling default nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling nodejs:20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing nodejs"

# Create roboshop user
id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
  VALIDATE $? "Creating roboshop user"
else
  echo -e "$G User already exists $N" | tee -a $LOG_FILE
fi

# Setup app directory
mkdir -p /app
VALIDATE $? "Creating app directory"
rm -rf /app/*

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading Catalogue"

cd /app
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Unzipping catalogue"

npm install &>>$LOG_FILE
VALIDATE $? "Installing node dependencies"

# Setup systemd service
cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_FILE
VALIDATE $? "Copying service file"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalogue &>>$LOG_FILE
systemctl restart catalogue &>>$LOG_FILE
VALIDATE $? "Starting catalogue service"

# Setup MongoDB repo
cp $SCRIPT_DIR/mongodb.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
VALIDATE $? "Copying MongoDB repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installing MongoDB Client"

# Load MongoDB Schema
MONGO_HOST="mongodb.daws84s.life"
SCHEMA_FILE="/app/db/master-data.js"

if [ ! -f $SCHEMA_FILE ]; then
  echo -e "$R ERROR: Schema file $SCHEMA_FILE not found $N" | tee -a $LOG_FILE
  exit 1
fi

echo "Testing MongoDB connection..." | tee -a $LOG_FILE
mongosh "mongodb://${MONGO_HOST}:27017/catalogue" --eval "db.stats()" &>>$LOG_FILE
if [ $? -ne 0 ]; then
  echo -e "$R ERROR: Cannot connect to MongoDB at ${MONGO_HOST} $N" | tee -a $LOG_FILE
  exit 1
fi

mongosh "mongodb://${MONGO_HOST}:27017/catalogue" < $SCHEMA_FILE &>>$LOG_FILE
VALIDATE $? "Loading MongoDB Schema"

