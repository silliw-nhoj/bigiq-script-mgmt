#####################################
# add or modify tacacs authentication
#####################################
active=$(tmsh show sys failover | awk '/active/ {print $2}')
if [ "$active" ] ; then
  # tacacs auth config
  secret="testsecret"
  defaulTacacsRole="auditor"
  tacacs1=10.10.100.20
  tacacs2=100.10.101.20
  tacacsCfg=$(tmsh list auth tacacs | awk '/^auth tacacs / {print $3}')
  
  echo "Executing script to push tacacs-auth against $(uname -n)"
  
  if [ "$tacacsCfg" ] ; then
    echo "Existing tacacs configuration found"
    tmsh list auth tacacs system-auth
    tmsh modify auth tacacs system-auth { secret $secret servers replace-all-with { $tacacs1 $tacacs2 } service ppp }
    echo "Taccacs configuration modified"
    tmsh list auth tacacs system-auth
  else
    echo "No existing tacacs configuration found"
    tmsh create auth tacacs system-auth { authentication use-all-servers debug enabled protocol ip secret $secret servers replace-all-with { $tacacs1 $tacacs2 } service ppp }
    echo "Taccacs configuration created"
    tmsh list auth tacacs system-auth
  fi
  echo "Previous authentication source type"
  tmsh list auth source type
  tmsh modify auth source type tacacs
  echo "Current authentication source type"
  tmsh list auth source type
  
  # set the default remote-user role
  echo "Previous authentication remote-user role"
  tmsh list auth remote-user
  
  tmsh modify auth remote-user default-role $defaulTacacsRole
  
  echo "Current authentication remote-user role"
  tmsh list auth remote-user  
  
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
