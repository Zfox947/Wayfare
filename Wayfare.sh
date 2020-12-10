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

#any user can change their username or password
# editProfile() {
#
# }

#designated admin only
# changeMemberStatus() {
#
# }

beginSession() {
	if [ "$1" == "visitor" ]; then
		echo "Signed in as visitor. Type 'exit' to exit Wayfare or 'view' to view a post."
		read option
		if [ "$option" == "exit" ]; then
			exit
		elif [ "$option" == "view" ]; then
			viewPost $1
		else
			echo "invalid option."
			beginSession $1
		fi
	else
		echo "Signed in as $1. Type 'exit' to exit Wayfare, 'view' to view a post,
    'write' to create a new post, or 'delete' to delete a post"
		read option
		if [ "$option" == "exit" ]; then
                        exit
		elif [ "$option" == "write" ]; then
			writePost $1
		elif [ "$option" == "delete" ]; then
			deletePost $1
		elif [ "$option" == "view" ]; then
                        viewPost $1
                else
                        echo "invalid option."
                        beginSession $1
                fi
	fi
}

writePost() {
	
	queryUid="SELECT Uid from USERS WHERE Uname = '$1';"
	queryUid2="SELECT Ismember from USERS WHERE Uname = '$1';"
     	
	read -ra Uid <<< $(mysql -D"$DB_NAME" -u "$SQL_USER" -p"$SQL_PASS" -se "$queryUid")
	read -ra isMember <<< $(mysql -D"$DB_NAME" -u "$SQL_USER" -p"$SQL_PASS" -se "$queryUid2")
	
	if [ "$isMember" == 1 ]; then 
		
		read -p "Please enter the location you visited (case sensitive):" -n 32 -e location
		read -p "Please enter a comment on your visit, Press enter to be done :" -n 255 -e comment
		
		queryLocationid="select Locationid from LOCATION where Location = '$location';"
		read -ra locationid <<< $(mysql -D"$DB_NAME" -u "$SQL_USER" -p"$SQL_PASS" -se "$queryLocationid")
		
		queryLocation="select Location from LOCATION where Location = '$location';"
        	read -ra isLocation <<< $(mysql -D"$DB_NAME" -u "$SQL_USER" -p"$SQL_PASS" -se "$queryLocation")
        	
		echo "$isLocation is location"
		echo "$location location"

		if [ "$isLocation" == "$location" ]; then
               	        echo "location found"
		else
                        echo "creating location"
                        enterLocation="INSERT into LOCATION (Location) values ('$location');"
                        mysql -D"$DB_NAME" -u "$SQL_USER" -p"$SQL_PASS" -e "$enterLocation"
		fi

		echo "Creating post..."
		
		dateUse=$(TZ=EEST date +"%F %T")
		echo $dateUse
		
		queryCreate="INSERT into DATA (Uid, Date, Comment, Locationid) values ('$Uid','$dateUse','$comment','$locationid');"
		mysql -D"$DB_NAME" -u "$SQL_USER" -p"$SQL_PASS" -e "$queryCreate" 
		echo "Post created at:"
		date +'%F %T'
		
		#enter this into the DATA table. make sure to get datetime
	else 
		echo "You are not a member, Returning to options."
		beginSession $1
	fi
}
#
# viewPost() {
#
# }
#
# deletePost() {
#
# }

signIn
