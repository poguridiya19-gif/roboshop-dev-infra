#!/bin/bash

# component=$1

# dnf install ansible -y
# ansible-pull -U https://github.com/poguridiya19-gif/ansible-roboshop-roles-tf.git -e component=mongodb main.yaml

# REPO_URL=https://github.com/poguridiya19-gif/ansible-roboshop-roles-tf.git
# REPO_DIR=/opt/roboshop/ansible
# ANSIBLE_DIR=ansible-roboshop-role-tf

# mkdir -p $REPO_DIR
# mkdir -P /var/log/roboshop/
# touch ansible.log
# cd $REPO_DIR
# CHECK IF ANSIBLE REPO IS ALREADY CLONED OR NOT

# if [-d $ANSIBLE_DIR];then
#     cd $ANSIBLE_DIR
#     git pull
# else 
#     git clone $REPO_URL
#     cd $ANSIBLE_DIR
# fi
# ansible-playbook -e component=$component main.yaml