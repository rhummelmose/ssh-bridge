#!/bin/bash

while [ $# -gt 0 ]; do
  case "$1" in
    --mode=*)
      run_mode="${1#*=}"
      ;;
    *)
      printf "****************************\n"
      printf "* Error: Invalid argument. *\n"
      printf "****************************\n"
      exit 1
  esac
  shift
done

if [ -z $run_mode ] || ! [[ "$run_mode" =~ ^(local|remote)$ ]]; then
    echo "Plese specify mode with --mode=local|remote .."
    exit 1
fi

if [ -z "${AUTHORIZED_KEYS_BASE64}" ]; then
  echo "Need your base64 encoded ssh public keys as AUTHORIZED_KEYS_BASE64 env variable. Abnormal exit ..."
  exit 1
fi

if [ -z "${PUBLIC_HOST_PORT}" ] && [[ $run_mode == "remote" ]]; then
  echo "Need remote SSH server's port as PUBLIC_HOST_PORT env variable. Abnormal exit ..."
  exit 1
fi

if [ -z "${PUBLIC_HOST_ADDR}" ] && [[ $run_mode == "remote" ]]; then
  echo "Need remote SSH server's server address as PUBLIC_HOST_ADDR env variable. Abnormal exit ..."
  exit 1
fi

if [ -z "${TUNNEL_PORT}" ] && [[ $run_mode == "remote" ]]; then
  echo "Need remote SSH server's tunnel port as TUNNEL_PORT env variable. Abnormal exit ..."
  exit 1
fi

if [ -z "${PRIVATE_KEY_BASE64}" ] && [[ $run_mode == "remote" ]]; then
  echo "Need remote SSH server's private key base64 encoded as PRIVATE_KEY_BASE64 env variable. Abnormal exit ..."
  exit 1
fi

echo "Populating /root/.ssh/authorized_keys with decoded value from AUTHORIZED_KEYS_BASE64 env variable ..."
echo -n "${AUTHORIZED_KEYS_BASE64}" | base64 -d > /root/.ssh/authorized_keys

if [[ $run_mode == "local" ]]; then

    echo "Starting sshd ..."
    /usr/sbin/sshd -D -e

elif [[ $run_mode == "remote" ]]; then

    echo "Populating /root/.ssh/remote_id_key with decoded value from PRIVATE_KEY_BASE64 env variable ..."
    echo -n "${PRIVATE_KEY_BASE64}" | base64 -d > /root/.ssh/remote_id_key
    chmod 700 /root/.ssh/remote_id_key

    echo "Starting sshd ..."
    /usr/sbin/sshd -e

    echo "Setting up the reverse ssh tunnel ..."
    while true
    do
        autossh -M 0 -o StrictHostKeyChecking=no -i /root/.ssh/remote_id_key -NgR ${TUNNEL_PORT}:localhost:22 root@${PUBLIC_HOST_ADDR} -p ${PUBLIC_HOST_PORT}
        echo "=> Tunnel Link down!"
        echo "=> Wait 15 seconds to reconnect"
        sleep 15
        echo "=> Reconnecting..."
    done

fi
