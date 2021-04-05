#!/bin/bash
clear

list=$(awk '{print $1}' ~/.ssh/known_hosts |sed -e 's/,/ /g' | sort -u )
listsorted=$(printf "%s\n" "${list[@]}" | sort -u)

##colors and user
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
USER="root"

echo > /tmp/sshstat.txt
for host in $listsorted ;
    do
      ssh -oBatchMode=yes -oConnectTimeout=2  ${USER}@"${host}" "exit" >/tmp/sshstat.txt 2>&1
      ret=$?
      if [ $ret -ne 0 ]; then
        echo -e "${RED}Failed:${NC} $host"
        echo sed -i.bak \"/"$host"/d\" "$HOME/.ssh/known_hosts" | sh
      else
        echo -e "${GREEN}Success:${NC} $host"
        grep "Offending RSA" /tmp/sshstat.txt |  sed -e 's/:/ /g' | awk '{printf "sed -i.bak -e \"%dd\" %s  \n", $6, "$HOME/.ssh/known_hosts" }' | sh
      fi
done

echo "$list"
