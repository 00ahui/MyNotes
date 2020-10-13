LOCALIP=`gethostip -d n0.manager.node.cluster.local`
TOKEN=`awk -F '"' '{print $4}' /tmp/session.json`
URI=$1
curl -i -k -H 'Accept:application/json' -H 'Content-Type:application/json;charset=utf8' -H "X-Auth-Token:${TOKEN}" -G https://${LOCALIP}:26335${URI}
