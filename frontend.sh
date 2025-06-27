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

# Check if the user is root
if [ "$USERID" -ne 0 ]; then
  echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
  exit 1
else
  echo "You are running with root access" | tee -a $LOG_FILE
fi

# Validate function
VALIDATE(){
  if [ $1 -eq 0 ]; then
    echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
  else
    echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
    exit 1
  fi
}

# Install unzip if not present
dnf install unzip -y &>>$LOG_FILE
VALIDATE $? "Installing unzip"

# Install Nginx
dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "Disabling Default Nginx"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "Enabling Nginx Repo"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Installing Nginx"

# Check nginx config before starting
nginx -t &>>$LOG_FILE
VALIDATE $? "Nginx Configuration Check"

# Enable and Start Nginx
systemctl enable nginx &>>$LOG_FILE
VALIDATE $? "Enable Nginx"

systemctl start nginx &>>$LOG_FILE
VALIDATE $? "Start Nginx"

# Remove default content
rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Removing default content"

# Download frontend content
curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend.zip &>>$LOG_FILE
VALIDATE $? "Downloading frontend"

# Extract frontend content
cd /usr/share/nginx/html
VALIDATE $? "Changing to HTML folder"

unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Unzipping frontend"

# Replace nginx.conf
rm -rf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "Removing default nginx.conf"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "Copying new nginx.conf"

# Final config check and restart
nginx -t &>>$LOG_FILE
VALIDATE $? "Final Nginx Config Test"

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "Restarting nginx"
