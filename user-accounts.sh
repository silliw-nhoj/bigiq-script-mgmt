#####################################
# add user authorization config
#####################################
active=$(tmsh show sys failover | awk '/active/ {print $2}')
if [ "$active" ] ; then

  # admin users
  adminUsers="admin1 admin2 admin3"
  
  echo "Executing script to add users against $(uname -n)"

  echo "Pre-change list of admin users"
  tmsh list auth user | awk '/^auth user/ {user=$3} / role / {role=$2} /^}/ {print user,role}' | while read user role; do
    if [ "$role" == "admin" ] ; then
      echo $user
    fi
  done
  
  for u in $(echo $adminUsers); do
    tmsh create auth user $u description $u partition-access replace-all-with { all-partitions { role admin } } shell bash
  done
  
  ver=$(tmsh list sys soft volume | awk '/^sys software/ {vol=$4;active=0} / active/ {active=1} / version / {ver=$2} /^}/ {if (active) print ver}')
  if [ "$ver" \> 12 ] ; then 
    for u in $(echo $adminUsers); do
      tmsh create auth user $u description $u partition-access replace-all-with { all-partitions { role admin } } shell bash
    done
  else 
    for u in $(echo $adminUsers); do
      tmsh create auth user $u description $u partition-access all role admin shell bash
    done
  fi
    
  echo "Post-change list of admin users"
  tmsh list auth user | awk '/^auth user/ {user=$3} / role / {role=$2} /^}/ {print user,role}' | while read user role; do
    if [ "$role" == "admin" ] ; then
      echo $user
    fi
  done

  # save config
  tmsh save sys config

  # sleep for 5 seconds to allow per time to update
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

