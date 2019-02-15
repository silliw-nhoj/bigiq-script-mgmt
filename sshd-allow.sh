#####################################
# modify sshd allow-list
#####################################
active=$(tmsh show sys failover | awk '/active/ {print $2}')
if [ "$active" ] ; then
  # ssh allow list
  sshAllow="172.20.5.0/24 172.19.5.0/24 10.107.212.0/24 10.106.253.0/24 10.107.253.0/24"
  
  echo "Executing script to modify ssh allow-list against $(uname -n)"  
  
  # modify ssh allow list
  echo "Pre-change sshd allow-list"
  tmsh list sys sshd allow
  
  tmsh modify sys sshd allow replace-all-with { $sshAllow }

  echo "Post-change sshd allow-list"
  tmsh list sys sshd allow

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
