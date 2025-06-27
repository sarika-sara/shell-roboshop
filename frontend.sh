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

# Check if root
if [ "$USERID" -ne 0 ]; then
  echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
  exit 1
else
  echo "You are running with root access" | tee -a $LOG_FILE
fi

# Validator
VALIDATE(){
  if [ $1 -eq 0 ]; then
    echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
  else
    echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
    exit 1
  fi
}

# Install unzip (needed for frontend)
dnf install unzip -y &>>$LOG_FILE
VALIDATE $? "Installing unzip"

# Install Nginx
dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "Disabling Default Nginx"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "Enabling Nginx 1.24"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Installing Nginx"

# Download and unzip frontend
rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Removing default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend.zip &>>$LOG_FILE
VALIDATE $? "Downloading frontend"

cd /usr/share/nginx/html
VALIDATE $? "Changing directory to nginx html"

unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Unzipping frontend"

# Fix Nginx config
cat <<EOF > /etc/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    sendfile on;
    keepalive_timeout 65;

    server {
        listen 80;
        server_name roboshop.internal;

        location / {
            root /usr/share/nginx/html;
            index index.html index.htm;
        }
    }
}
EOF
VALIDATE $? "Writing valid nginx.conf"

# Test and restart nginx
nginx -t &>>$LOG_FILE
VALIDATE $? "Testing nginx.conf"

systemctl enable nginx &>>$LOG_FILE
VALIDATE $? "Enabling Nginx"

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "Starting Nginx"
