# source docker helpers
. util/docker.sh

# setup() {
#   start_container "simple-single" "192.168.0.2"
# }

# teardown() {
#   stop_container "simple-single"
# }

@test "Start Local Container" {
  start_container "simple-single-local" "192.168.0.2"
}

@test "Configure Local Container" {
  run run_hook "simple-single-local" "default-configure" "$(payload default/configure-local)"

  [ "$status" -eq 0 ] 
}

@test "Start Local MySQL" {
  run run_hook "simple-single-local" "default-start" "$(payload default/start)"
  [ "$status" -eq 0 ]
  # Verify
  run docker exec simple-single-local bash -c "ps aux | grep [m]ysqld"
  [ "$status" -eq 0 ] 
}

@test "Stop Local MySQL" {
  run run_hook "simple-single-local" "default-stop" "$(payload default/stop)"
  [ "$status" -eq 0 ]
  while docker exec "simple-single-local" bash -c "ps aux | grep [m]ysqld"
  do
    sleep 1
  done
  # Verify
  run docker exec simple-single-local bash -c "ps aux | grep [m]ysqld"
  [ "$status" -eq 1 ] 
}

@test "Stop Local Container" {
  stop_container "simple-single-local"
}

@test "Start Production Container" {
  start_container "simple-single-production" "192.168.0.2"
}

@test "Configure Production Container" {
  run run_hook "simple-single-production" "default-configure" "$(payload default/configure-production)"

  [ "$status" -eq 0 ] 
}

@test "Start Production MySQL" {
  run run_hook "simple-single-production" "default-start" "$(payload default/start)"
  [ "$status" -eq 0 ]
  # Verify
  run docker exec simple-single-production bash -c "ps aux | grep [m]ysqld"
  [ "$status" -eq 0 ] 
}

@test "Stop Production MySQL" {
  run run_hook "simple-single-production" "default-stop" "$(payload default/stop)"
  [ "$status" -eq 0 ]
  while docker exec "simple-single-production" bash -c "ps aux | grep [m]ysqld"
  do
    sleep 1
  done
  # Verify
  run docker exec simple-single-production bash -c "ps aux | grep [m]ysqld"
  [ "$status" -eq 1 ] 
}

@test "Stop Production Container" {
  stop_container "simple-single-production"
}