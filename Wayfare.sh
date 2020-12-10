#!/bin/bash
# Wayfare Bash script

#Thomas, you will need to decide if you would like the script to require 2 variables as a pass in for username and password and then check for those in the database. if it isn't in databse then theoretically you would need to ask for
#if they would like to create a new account or try logging in again. if they want to create a new account then ask for the other info needed.
#or, have them pass a single parameter asking them if they are a member then if they are then the script asks them for uname and password and if they aren't then go through a create account option
#in order to do my part this needs to be decided so i can access the variable for uid thats created and should be held throughout the script

DB_NAME="WayfareZGTV"
SQL_USER="zfox"
SQL_PASS="flipburger"

signIn() {
  echo "Welcome to Wayfare! Please enter 'register', 'login' or 'visitor' to proceed."
  read loginChoice
  if [ "$loginChoice" == "register" ]; then
    validateNewUser
  elif [ "$loginChoice" == "visitor" ]; then
    beginSession $loginChoice
  elif [ "$loginChoice" == "login" ]; then
    validateUsername
  else
    echo "Your choice was not entered correctly."
    signIn;
  fi
}

validateNewUser() {
  echo "Please enter a username for your new profile."
  read username
  echo "Please enter a password for your new profile."
  read password
  echo "Please enter your password again."
  read password2
  if [ "$password" != "$password2" ]; then
    echo "Your credentials did not match. Please try again."
    validateNewUser
  else
    createUser $username $password;
  fi
}

createUser() {
  uid=$(uuidgen)
  hash="$(echo -n "$2" | md5sum )"
  echo $hash
  queryCreate="INSERT into USERS (Uid, Uname, Passwd, Ismember) values ('$uid', '$1', '$hash', 1);"
  mysql -u "$SQL_USER" -p"$SQL_PASS" -e "$queryCreate" "$DB_NAME"
  echo "Your profile was registered successfully. Proceeding to login."
  beginSession $1
}

validateUsername() {
  echo "Please enter your username."
  read username
  echo "Please enter your password."
  read password
  sqlLogin $username $password
}

sqlLogin() {
  hash="$(echo -n "$2" | md5sum )"
  queryLogin="SELECT Uname, Passwd from USERS WHERE Uname='$1' AND Passwd='$hash';"
  if [ "$(mysql -u "$SQL_USER" -p"$SQL_PASS" -e "$queryLogin" "$DB_NAME")" ]; then
    beginSession $1
  else
    echo "Your credentials were unable to be verified. Type 'again' to try again or 'home' to return to the main menu."
    read badCredentialsRes
    if [ "$badCredentialsRes" == "again" ]; then
      validateUsername
    elif [ "$badCredentialsRes" == "home" ]; then
      signIn
    else
      echo "Your choice was not entered correctly. You will be redirected to the main menu."
      signIn;
    fi
  fi
}

beginSession() {
	if [ "$1" = "visitor" ]; then
		echo "Signed in as visitor. Type 'exit' to exit Wayfare or 'view' to view a post."
		read option
		if [ "$option" = "exit" ]; then
			exit
		elif [ "$option" = "view" ]; then
			viewPost
		else
			echo "invalid option."
			beginSession
		fi
	else
		echo "Signed in as $1. Type 'exit' to exit Wayfare, 'view' to view a post,
    'write' to create a new post, or 'delete' to delete a post"
		read option
		if [ "$option" = "exit" ]; then
                        exit
		elif [ "$option" = "write" ]; then
			writePost
		elif [ "$option" = "delete" ]; then
			deletePost
		elif [ "$option" = "view" ]; then
                        viewPost
                else
                        echo "invalid option."
                        beginSession
                fi
	fi
}

# writePost() {
#
# }
#
# viewPost() {
#
# }
#
# deletePost() {
#
# }

signIn
