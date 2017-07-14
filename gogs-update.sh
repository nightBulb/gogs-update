#!/bin/bash

logd () {
	# $1: log tag
	# $2: message
	echo "[$1]: $2"
}

logw () {
	echo -e "[\e[44mWARN: $1\e[0m]: $2"
}

loge () {

	echo -e "[\e[41mERROR: $1\e[0m]: $2"
}

preUpdate () {
	local LOGTAG="preUpdate"
	
	local GOGS_PARENT_DIR=$1
	local GOGS_USER=$2

	local RUN_AS_USER="sudo -u $GOGS_USER"

	logd $LOGTAG "Gogs Parent DIR:$GOGS_PARENT_DIR"
	
	logd $LOGTAG "Stopping Gogs Service if its running"
	systemctl stop gogs.service
		
	if [ -d $GOGS_PARENT_DIR/gogs ]; then
		
		logd $LOGTAG "Existing Gogs Directory Found"
		
		if [ -d $GOGS_PARENT_DIR/gogs_old ]; then
			logd $LOGTAG "Existing gogs_old directory Found"
			if [ -d $GOGS_PARENT_DIR/gogs/custom ] && [ -d $GOGS_PARENT_DIR/gogs/data ] && [ -d $GOGS_PARENT_DIR/gogs/log ]; then
				logd $LOGTAG "User data for Gogs exists in current gogs folder"
				logd $LOGTAG "Deleting old backup folder"
				$RUN_AS_USER rm -r $GOGS_PARENT_DIR/gogs_old

				logd $LOGTAG "Moving gogs to gogs_old"
				$RUN_AS_USER mv $GOGS_PARENT_DIR/gogs $GOGS_PARENT_DIR/gogs_old
			else
				logw $LOGTAG "User data does not exist in current gogs folder"
				$RUN_AS_USER rm -r $GOGS_PARENT_DIR/gogs

			fi
	
		else
			logw $LOGTAG "No pre-existing/backup gogs_old directory found"
	        fi
		

	elif [ -d $GOGS_PARENT_DIR/gogs_old ]; then
		logd $LOGTAG "No existing Gogs DIR but old/backup exists"
		return 0
	else
		logw $LOGTAG "No Existing Gogs Directory Found"
		return 1
	fi

}

doUpdate () {
	local LOGTAG="update"
	
	local GOGS_PARENT_DIR=$1
	local NEW_GOGS_ZIP=$2
	local GOGS_USER=$3
	

	logd $LOGTAG "Unzipping new gogs"
	sudo -u $GOGS_USER unzip $NEW_GOGS_ZIP -d $GOGS_PARENT_DIR
}

postUpdate () {
	local LOGTAG="postUpdate"

	local GOGS_PARENT_DIR=$1
	local GOGS_USER=$2

	local RUN_AS_USER="sudo -u $GOGS_USER"

	logd $LOGTAG "Gogs Dir:$GOGS_PARENT_DIR, Gogs User:$GOGS_USER"
	
	if [ -d $GOGS_PARENT_DIR/gogs ]; then
	
		logd $LOGTAG "Gogs Directory found, looking for old directory"

		if [ -d $GOGS_PARENT_DIR/gogs_old ]; then
			logd $LOGTAG "Old Gogs Directory Found, Copying old data"
			
			$RUN_AS_USER cp -R $GOGS_PARENT_DIR/gogs_old/custom 	$GOGS_PARENT_DIR/gogs
			$RUN_AS_USER cp -R $GOGS_PARENT_DIR/gogs_old/data 	$GOGS_PARENT_DIR/gogs
			$RUN_AS_USER cp -R $GOGS_PARENT_DIR/gogs_old/log 	$GOGS_PARENT_DIR/gogs
		else
			loge $LOGTAG "NOT FOUND: Old gogs directory, either this is first time installation or something went wrong during update and old data was not backed up"
		fi
	else
		loge $LOGTAG "No new Gogs folder found!!"
	fi
}

printUsage () {
	echo
	echo "Usage: sudo sh $0 gogs_parent_directory new_gogs_zip"
	echo
	echo "gogs_parent_directory:"
	echo "Must be absolute path to parent directory of Gogs installation"
	echo
	echo "new_gogs_zip:"
	echo "Must be a file path which is accessible to Gogs user(git)"
	echo

}

main () {
	local LOGTAG="main"
	
	local GOGS_PARENT_DIR=$1
	local UPDATE_ZIP_FILE=$2

	if [ -z $GOGS_PARENT_DIR ]; then
		echo "ERROR: Gogs Parent path parameter missing!!"
		printUsage
		exit 1
	fi

	if [ -z $UPDATE_ZIP_FILE ]; then
		echo "ERROR: Gogs Update zip file missing!!"
		printUsage
		exit 1
	fi

	local GOGS_USER="git"
	
	printUsage
        logd $LOGTAG "Starting Gogs update"


	
	preUpdate $GOGS_PARENT_DIR $GOGS_USER
	
	if [ $? -ne 0 ]; then
		loge $LOGTAG "Pre Update Failed"
		exit 1
	fi

	doUpdate $GOGS_PARENT_DIR $UPDATE_ZIP_FILE $GOGS_USER

	postUpdate $GOGS_PARENT_DIR $GOGS_USER
}

main $1 $2
