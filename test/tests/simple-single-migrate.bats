# source docker helpers
. util/docker.sh

# setup() {
#   start_container "simple-single" "192.168.0.2"
# }

# teardown() {
#   stop_container "simple-single"
# }

echo_lines() {
  for (( i=0; i < ${#lines[*]}; i++ ))
  do
    echo ${lines[$i]}
  done
}

@test "Start Old Container" {
  start_container "simple-single-old" "192.168.0.2"
}

@test "Configure Old Container" {
  run run_hook "simple-single-old" "default-configure" "$(payload default/configure-production)"

  [ "$status" -eq 0 ] 
}

@test "Start Old MySQL" {
  run run_hook "simple-single-old" "default-start" "$(payload default/start)"
  [ "$status" -eq 0 ]
  # Verify
  run docker exec simple-single-old bash -c "ps aux | grep [m]ysqld"
  [ "$status" -eq 0 ] 
}

@test "Start New Container" {
  start_container "simple-single-new" "192.168.0.3"
}

@test "Configure New Container" {
  run run_hook "simple-single-new" "default-configure" "$(payload default/configure-production)"
  [ "$status" -eq 0 ] 
}

@test "Start New MySQL" {
  run run_hook "simple-single-new" "default-start" "$(payload default/start)"
  [ "$status" -eq 0 ]
  # Verify
  run docker exec simple-single-new bash -c "ps aux | grep [m]ysqld"
  [ "$status" -eq 0 ] 
}

@test "Stop New MySQL" {
  run run_hook "simple-single-new" "default-stop" "$(payload default/stop)"
  [ "$status" -eq 0 ]
  while docker exec "simple-single-new" bash -c "ps aux | grep [m]ysqld"
  do
    sleep 1
  done
  # Verify
  run docker exec simple-single-new bash -c "ps aux | grep [m]ysqld"
  [ "$status" -eq 1 ] 
}

@test "Start New SSHD" {
  # start ssh server
  run docker exec simple-single-new /opt/gonano/sbin/sshd
  [ "$status" -eq 0 ]
  run docker exec simple-single-new bash -c "ps aux | grep [s]shd"
  [ "$status" -eq 0 ]
}

@test "Pre-Export Old MySQL" {
  run run_hook "simple-single-old" "default-single-pre_export" "$(payload default/single/pre_export)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Stop Old MySQL" {
  run run_hook "simple-single-old" "default-stop" "$(payload default/stop)"
  [ "$status" -eq 0 ]
  while docker exec "simple-single-old" bash -c "ps aux | grep [m]ysqld"
  do
    sleep 1
  done
  # Verify
  run docker exec simple-single-old bash -c "ps aux | grep [m]ysqld"
  [ "$status" -eq 1 ] 
}

@test "Export Old MySQL" {
  run run_hook "simple-single-old" "default-single-export" "$(payload default/single/export)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Restart New MySQL" {
  run run_hook "simple-single-new" "default-start" "$(payload default/start)"
  [ "$status" -eq 0 ]
  # Verify
  run docker exec simple-single-new bash -c "ps aux | grep [m]ysqld"
  [ "$status" -eq 0 ] 
}

@test "Stop Old Container" {
  stop_container "simple-single-old"
}

@test "Stop New Container" {
  stop_container "simple-single-new"
}