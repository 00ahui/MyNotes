LOCALIP=`gethostip -d n0.manager.node.cluster.local`
curl -s -k -H 'Accept:application/json' -H 'Content-Type:application/json;charset=utf8' -X PUT https://${LOCALIP}:26335/rest/plat/smapp/v1/sessions -d '
{
  "grantType": "password",
  "userName": "wangyaohui",
  "value": "Changeme_123"
}' > /tmp/session.json

awk -F '"' '{print $4}' /tmp/session.json
