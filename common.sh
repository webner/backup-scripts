#!/bin/bash
set -o nounset
source "logger.sh"

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
