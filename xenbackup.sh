#!/bin/bash
# Required mount point: nas-n.mgt.couchbase.com:/data/builds
# Required ENV: UUID, BACKUP_NAME, CLUSTER

BACKUP_DIR="/builds/backups/xen/${CLUSTER}"

if [ ! -d /builds/backups/xen/ ]; then
	echo "Required backup directory does not exist: /builds/backups/xen/"
    exit 1
else
    mkdir -p ${BACKUP_DIR}
fi

# Convert YAML to JSON Xen credentials
# Required mount point: -v /home/couchbase/update_system_info/servers.yaml:/etc/servers.yaml
# default --json-output /etc/xenbackup.json
# default --file /etc/servers.yaml
./xen-credential-yaml-to-json.py --repository ${BACKUP_DIR} || exit 1

# Run Backup
# default: --config-file /etc/xenbackup.json
NAME_OPTION=''
if [ ! -z "${BACKUP_NAME}" ]; then
    	NAME_OPTION="--backup-name ${BACKUP_NAME}"
fi
./xenbackup backup ${UUID} --cluster ${CLUSTER} ${NAME_OPTION} || exit 1


# Publish to S3
# Required mount point: -v /home/couchbase/jenkinsdocker-ssh:/home/couchbase/.ssh
s3cmd -c /home/couchbase/.ssh/live.s3cfg put /builds/backups/xen/${CLUSTER}/${UUID}/*.xva s3://xen-${CLUSTER}/ || exit 1
