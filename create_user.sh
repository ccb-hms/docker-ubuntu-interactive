#!/command/with-contenv /bin/bash

# if username and password were not provided, exit.
# otherwise, create the user, add to groups, and modify file system permissions
if [[ -z $CONTAINER_USER_USERNAME ]] || [[ -z $CONTAINER_USER_PASSWORD ]];
then
	exit 1
else
    useradd $CONTAINER_USER_USERNAME
	mkdir /home/${CONTAINER_USER_USERNAME}
	chown ${CONTAINER_USER_USERNAME}:${CONTAINER_USER_USERNAME} /home/${CONTAINER_USER_USERNAME}
	chown ${CONTAINER_USER_USERNAME}:${CONTAINER_USER_USERNAME} /HostData
	addgroup ${CONTAINER_USER_USERNAME} staff
	echo "$CONTAINER_USER_USERNAME:$CONTAINER_USER_PASSWORD" | chpasswd
	adduser ${CONTAINER_USER_USERNAME} sudo
	chsh -s /bin/bash ${CONTAINER_USER_USERNAME}
fi
