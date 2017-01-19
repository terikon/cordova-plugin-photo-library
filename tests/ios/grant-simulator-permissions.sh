TCCDB_PATH=$HOME/Library/Developer/CoreSimulator/Devices/$(bash tests/ios/get-booted-simulator.sh)/data/Library/TCC/TCC.db
echo trying to insert permission
sqlite3 $TCCDB_PATH "insert into access(service, client, client_type, allowed, prompt_count, csreq) values('kTCCServicePhotos', 'io.cordova.hellocordova', 0, 1, 1, NULL)"
rc=$?
if [[ $rc != 0 ]]; then
  echo updating permission instead of inserting
  sqlite3 $TCCDB_PATH "update access set client_type=0, allowed=1, prompt_count=1, csreq=NULL where service='kTCCServicePhotos' and client='io.cordova.hellocordova'"
fi
