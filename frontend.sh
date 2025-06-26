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

# check the user has root privileges or not
if [ "$USERID" -ne 0 ]; then
  echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
  exit 1
else
  echo "You are running with root access" | tee -a $LOG_FILE
fi

# validate function takes input as exit status, what command they tried to install
VALIDATE(){
  if [ $1 -eq 0 ]; then
    echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
  else
    echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
    exit 1
  fi
}

# Install Nginx
dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "Disabling Default Nginx"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "Enabling Nginx"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Install Nginx"

# Start & Enable Nginx
systemctl enable nginx &>>$LOG_FILE
systemctl start nginx
VALIDATE $? "Start Nginx"

# Remove default content
rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Removing default content"

# Download frontend content
curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend.zip &>>$LOG_FILE
VALIDATE $? "Downloading frontend"

# Extract frontend content
cd /usr/share/nginx/html
unzip /tmp/frontend.zip 
VALIDATE $? "unzipping frontend" &>>$LOG_FILE

# Update nginx.conf
rm -rf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "Remove default nginx conf"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copying nginx.conf"

systemctl restart nginx 
VALIDATE $? "Restarting nginx"