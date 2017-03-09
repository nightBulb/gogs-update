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

	logd $LOGTAG "Gogs Parent DIR:$GOGS_PARENT_DIR"
	
	logd $LOGTAG "Stopping Gogs Service if its running"
	systemctl stop gogs.service
		
	if [ -d $GOGS_PARENT_DIR/gogs ]; then
		
		logd $LOGTAG "Existing Gogs Directory Found"
		
		if [ -d $GOGS_PARENT_DIR/gogs_old ]; then
			logd $LOGTAG "Existing gogs_old directory Found"
			rm -r gogs_old
		else
			logw $LOGTAG "No pre-existing/backup gogs_old directory found"
	        fi
		
		logd $LOGTAG "Moving gogs to gogs_old"
		mv $GOGS_PARENT_DIR/gogs $GOGS_PARENT_DIR/gogs_old

	elif [ -d $GOG_PARENT_DIR/gogs_old ]; then
		logd $LOGTAG "No existing Gogs DIR but old/backup exists"
		return 0
	else
		logw $LOGTAG "No Existing Gogs Directory Found"
		return 1

	fi

}

update () {
	local LOGTAG="update"
	local GOGS_PARENT_DIR=$1
	local NEW_GOGS_ZIP=$2
	

	logd $LOGTAG "Unzipping new gogs"

	unzip $NEW_GOGS_ZIP -d $GOGS_PARENT_DIR
}

postUpdate () {
	local LOGTAG="postUpdate"

	local GOGS_PARENT_DIR=$1
	logd $LOGTAG "Gogs Dir:$GOGS_PARENT_DIR"
	
	if [ -d $GOGS_PARENT_DIR/gogs ]; then
	
		logd $LOGTAG "Gogs Directory found, looking for old directory"

		if [ -d $GOGS_PARENT_DIR/gogs_old ]; then
			log $LOGTAG "Old Gogs Directory Found, Copying old data"
			
			cp -R $GOGS_PARENT_DIR/gogs_old/custom gogs
			cp -R $GOGS_PARENT_DIR/gogs_old/data gogs
			cp -R $GOGS_PARENT_DIR/gogs_old/log gogs
		else
			loge $LOGTAG "NOT FOUND: Old gogs directory, either this is first time installation or something went wrong during update and old data was not backed up"
		fi
	else
		loge $LOGTAG "No new Gogs folder found!!"
	fi
}

printUsage () {
	echo
	echo "Usage: $0 gogs_parent_directory new_gogs_zip"
	echo
}

main () {
	local LOGTAG="main"
	
	local GOGS_PARENT_DIR=$1
	local UPDATE_ZIP_FILE=$2
	
	printUsage
        logd $LOGTAG "Starting Gogs update"


	
	preUpdate $GOGS_PARENT_DIR
	
	if [ $? -ne 0 ]; then
		loge $LOGTAG "Pre Update Failed"
		exit 1
	fi

	update $GOGS_PARENT_DIR $UPDATE_ZIP_FILE

	postUpdate $GOGS_PARENT_DIR
}

main $1 $2
