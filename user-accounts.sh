#####################################
# add user authorization config
#####################################
active=$(tmsh show sys failover | awk '/active/ {print $2}')
if [ "$active" ] ; then

  # admin users
  adminUsers="brett vana john"
  
  echo "Executing script to add users against $(uname -n)"

  echo "Pre-change list of admin users"
  tmsh list auth user partition-access | awk '/^auth user/ {user=$3} / role / {role=$2} /^}/ {print user,role}' | while read user role; do
    if [ "$role" == "admin" ] ; then
      echo $user
    fi
  done
  
  for u in $(echo $adminUsers); do
    tmsh create auth user $u description $u partition-access replace-all-with { all-partitions { role admin } } shell bash
  done
  
  echo "Post-change list of admin users"
  tmsh list auth user partition-access | awk '/^auth user/ {user=$3} / role / {role=$2} /^}/ {print user,role}' | while read user role; do
    if [ "$role" == "admin" ] ; then
      echo $user
    fi
  done

  # save config
  tmsh save sys config

  # sleep for 5 seconds to allow peer time to update
  sleep 5
  
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

