#####################################
# modify remote-server syslog config
#####################################
active=$(tmsh show sys failover | awk '/active/ {print $2}')
if [ "$active" ] ; then

  # remote syslog
  rsyslog1=10.1.20.11
  rsyslog2=10.1.20.12

  echo "Executing script to modify remote-server syslog configuration against $(uname -n)"
  
  echo "Pre-change syslog remote-server config"
  tmsh list sys syslog remote-servers
  
  tmsh modify sys syslog remote-servers replace-all-with { remoteSyslog1 { host $rsyslog1 remote-port 514 } remoteSyslog2 { host $rsyslog2 remote-port 514 } }

  echo "Post-change syslog remote-server config"
  tmsh list sys syslog remote-servers
    
  # save config
  tmsh save sys config

  # sync config
  selfName=$(tmsh list cm device self-device | awk '/^cm device/ {name=$3} /self-device true/ {print name}')
  syncGroup=$(tmsh list cm device-group type | awk '/^cm device-group/ {name=$3} /^    type/ {type=$2} /^}/ { if ( type == "sync-failover" ) print name}')
  if [ "$syncGroup" ] ; then
    tmsh modify cm device-group $syncGroup devices modify { $selfName { set-sync-leader } }
    tmsh run cm config-sync to-group $syncGroup
  fi
else
  exit 0
fi
