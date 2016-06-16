#!/bin/sh

set -eu

echo "Content-type: text/plain"
echo ""

USER="zckr"
WANTED_INTERVAL="10"

URL="$1"

HOME="/home/${USER}"
PATH="${PATH}:${HOME}/bin/"
WSWSH_DIR="${HOME}/wswsh"
SCRIPTS_DIR="${WSWSH_DIR}/scripts"
VWWW_DIR="/var/www/virtual/$USER"
STAMP_DIR="${SCRIPTS_DIR}/stamps"
SRC_DIR="${WSWSH_DIR}/src/${URL}/"

UPDT_CMD="rsync -aPh --del"

CALLTIME="$(date +%s)"
LAST_CALLTIME="$(cat ${STAMP_DIR}/last.txt)"
INTERVAL=$(( ${CALLTIME} - ${LAST_CALLTIME} ))
TIME_LEFT="$(( ${WANTED_INTERVAL} - ${INTERVAL} ))"

function update {
	cd ${SRC_DIR}
	git pull
	cd ${WSWSH_DIR}/work/${URL}/
	${UPDT_CMD} ${SRC_DIR}/src/ src/
	mksh scripts/gen.sh
	${UPDT_CMD} --exclude="extra/" dest/ ${VWWW_DIR}/${URL}/
	${UPDT_CMD} ${WSWSH_DIR}/extra/${URL}/ ${VWWW_DIR}/${URL}/extra/
}

function check_interval {
	WAITING="$(cat ${STAMP_DIR}/waiting.txt)"
	if [[ ${WAITING} -eq 1 ]]; then
		CASE="2"
	else
		if [[ ${INTERVAL} -gt ${WANTED_INTERVAL} ]]; then
			CASE="0"
		else
			CASE="1"
		fi
	fi
}

function execute_update {
	update
	printf "%s\n" "${CALLTIME}" > ${STAMP_DIR}/last.txt
	printf "%d\n" '0' > ${STAMP_DIR}/waiting.txt
	exit 0
}

check_interval
case ${CASE} in
	2)
		printf "Update in queue. %d seconds left.\n" "${TIME_LEFT}"
		exit 2
		;;
	0)
		execute_update
		printf "%s\n" "${CALLTIME}" > ${STAMP_DIR}/last.txt
		exit 0
		;;
	1)
		printf "%d\n" '1' > ${STAMP_DIR}/waiting.txt
		TIME_LEFT="$(( ${WANTED_INTERVAL} - ${INTERVAL} ))"
		printf "Waiting for %d seconds.\n" "${TIME_LEFT}"
		sleep ${TIME_LEFT}
		execute_update
esac

