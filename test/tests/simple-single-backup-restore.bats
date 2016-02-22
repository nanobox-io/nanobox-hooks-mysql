# source docker helpers
. util/docker.sh

# setup() {
#   start_container "backup-restore" "192.168.0.2"
# }

# teardown() {
#   stop_container "backup-restore"
# }

@test "Start Container" {
  start_container "backup-restore" "192.168.0.2"
  run run_hook "backup-restore" "default-configure" "$(payload default/configure-production)"
  echo -e $output
  [ "$status" -eq 0 ] 
  run run_hook "backup-restore" "default-start" "$(payload default/start)"
  [ "$status" -eq 0 ]
  # Verify
  run docker exec backup-restore bash -c "ps aux | grep [m]ysqld"
  # [ "$status" -eq 0 ]
}

@test "Start Backup Container" {
  start_container "backup" "192.168.0.3"
  # generate some keys
  run run_hook "backup" "default-configure" "$(payload default/configure-production)"
  [ "$status" -eq 0 ]

  # start ssh server
  run docker exec backup /opt/gonano/sbin/sshd
  [ "$status" -eq 0 ]
  run docker exec backup bash -c "ps aux | grep [s]shd"
  [ "$status" -eq 0 ]
}

@test "Backup" {
  run run_hook "backup-restore" "default-backup" "$(payload default/backup)"
  echo $output
  [ "$status" -eq 0 ]
}

@test "Restore" {
  run run_hook "backup-restore" "default-restore" "$(payload default/restore)"
  echo $output
  [ "$status" -eq 0 ]
}

@test "Stop Container" {
  stop_container "backup-restore"
}

@test "Stop Backup Container" {
  stop_container "backup"
}