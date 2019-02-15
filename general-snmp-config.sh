#####################################
# modify snmp general configuration
#####################################
active=$(tmsh show sys failover | awk '/active/ {print $2}')
if [ "$active" ] ; then

  # set snmp variables
  allowedAddrs="10.106.253.14 10.106.253.16 10.20.156.68 10.106.253.69 10.106.253.2 10.106.253.18"
  community="community1"
  comString="w5rLroXC1bxG"

  echo "Executing script to modify general snmp configuration against $(uname -n)"
    
  # modify snmp allowed-addresses
  echo "Pre-change snmp allowed-addresses"
  tmsh list sys snmp allowed-addresses
  
  tmsh modify sys snmp allowed-addresses replace-all-with { $allowedAddrs }
  
  echo "Post-change snmp allowed-addresses"
  tmsh list sys snmp allowed-addresses

  # modify snmp communities
  echo "Pre-change snmp communities"
  tmsh list sys snmp communities
  
  tmsh modify sys snmp communities replace-all-with { $community { community-name $comString } }

  echo "Post-change snmp communities"
  tmsh list sys snmp communities
  
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
