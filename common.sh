#!/bin/bash
set -o nounset
source "$(dirname $0)/logger.sh"

BACKUP_NAMESPACE=${1-}
BACKUP_LABEL_SELECTOR=${BACKUP_LABEL_SELECTOR-catalysts.cc/backup=true}
BACKUP_TARGET=${BACKUP_TARGET-/backup}
BACKUP_REMOTE_USER=${BACKUP_REMOTE_USER-centos}
BACKUP_RSYNC_OPTS=(-aAS -e 'ssh -T -c aes256-ctr -o Compression=no -x' --info=stats --numeric-ids --ignore-errors --delete --rsync-path='sudo rsync')

function get_oc_selector() {
  local ARGS="-l ${BACKUP_LABEL_SELECTOR}"

  if [[ "$BACKUP_NAMESPACE" == "" ]]; then
    ARGS="$ARGS --all-namespaces"
  else
    ARGS="$ARGS -n $BACKUP_NAMESPACE"
  fi

  echo "$ARGS"
}

function get_nodes() {
  oc get nodes --no-headers -o custom-columns=name:.metadata.name
}

function prom_start() {
  PROM_START_TIME=$(date +%s%03N)
}

function _update_begin() {
  PROM_FILE=$1 

  if [[ -e "$PROM_FILE" ]]; then
   cp "$PROM_FILE" "${PROM_FILE}.temp"
  else 
   touch "${PROM_FILE}.temp"
  fi
}

function _update_value() {
  key=$1
  value=$2

  grep -q "^$key" ${PROM_FILE}.temp && 
    sed "s#\($key\).*#\1 $value#" -i ${PROM_FILE}.temp ||
    echo "${key} $value" >> ${PROM_FILE}.temp
}

function _update_commit() {
  chmod +r ${PROM_FILE}.temp
  mv ${PROM_FILE}.temp ${PROM_FILE}
}

function prom_end() {
  exitcode=$?
  PROM_NAME=$1
  PROM_LABELS=$2
  end=$(date +%s%03N)
  runtime=$((end-PROM_START_TIME))

  _update_begin ${BACKUP_TARGET}/metrics/${PROM_NAME}.prom
  _update_value "${PROM_NAME}_exitcode{$PROM_LABELS}" "$exitcode"
  _update_value "${PROM_NAME}_runtime_ms{$PROM_LABELS}" "$runtime"
  _update_commit
  
  return $exitcode
}

