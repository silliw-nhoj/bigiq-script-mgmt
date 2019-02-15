#####################################
# modify snmp process-monitors
#####################################
active=$(tmsh show sys failover | awk '/active/ {print $2}')
if [ "$active" ] ; then
  # set snmp community string
  comString="w5rLroXC1bxG"
  # process-monitors - process-name:max-processes
  procMons="bigd:1 chmand:1 httpd:infinity mcpd:1 sod:1 tmm:infinity"
  # traps - trap-name:destination-host:network
  traps="SNMPhost1:10.106.253.14:mgmt SNMPhost2:10.106.253.16:mgmt SNMPhost3:10.20.156.68:mgmt"

  echo "Executing script to modify snmp process-monitors against $(uname -n)"  
  
  # modify snmp process-monitors
  echo "Pre-change snmp process-monitors"
  tmsh list sys snmp process-monitors
  
  command="tmsh modify sys snmp process-monitors replace-all-with {"
  for pMon in $(echo $procMons); do
    read proc maxproc <<< $(echo $pMon | sed 's/:/ /g')
    command="$command $proc { max-processes $maxproc process $proc }"
  done
  command="$command }"
  $command
  
  echo "Post-change snmp process-monitors"
  tmsh list sys snmp process-monitors

  # modify snmp traps 
  echo "Pre-change snmp traps"
  tmsh list sys snmp traps
  
  command="tmsh modify sys snmp traps replace-all-with {"
  for trap in $(echo $traps); do
    read trapHost destHost net <<< $(echo $trap | sed 's/:/ /g')
    command="$command $trapHost { community $comString host $destHost network $net }"
  done
  command="$command }"
  $command
  
  echo "Post-change snmp traps"
  tmsh list sys snmp traps
  
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

