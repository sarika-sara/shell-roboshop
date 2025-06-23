#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

log_folder="/var/log/roboshop-logs"
script_name=$(echo $0 | cut -d "." -f1)
log_file="$log_folder/$script_name.log"

mkdir -p $LOGS_FOLDER
echo "Scipt started executing at: $(date)" | tee -a $LOG_FILE

#check the user has root privileges or not
if [ $USERID -eq 0 ]

then 
   echo -e "$G User has root access " | tee -a $LOG_FILE
else
   echo -e "$R User doesn't have root access " | tee -a $LOG_FILE
   exit 1 #give other than 0 upto 127
fi

# validate functions takes input as exit status,what command they tried to install
VALID() {
if [ $1 -eq 0 ]
then
    echo -e " $N Installation of $2 is ....$G Successful"
else
    echo -e "$N Installation of $2 is ....$R Failure"
    exit 1
fi 
}

cp mongodb.repo /etc/yum.repos.d/mongo.repo
VALID $? "copying Mongodb repo"

dnf install mongodb-org -y &>>$LOG_FILE
VALID $? "Installing mongodb server"

systemctl enable mongod &>>$LOG_FILE
VALID $? "Enabling MongoDB"

systemctl start mongod &>>$LOG_FILE
VALID $? "Starting MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALID $? "Editing MongoDB conf file for remote connections"

systemctl restart mongod &>>$LOG_FILE
VALID $? "Restarting MongoDB"