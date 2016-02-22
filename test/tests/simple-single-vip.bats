# source docker helpers
. util/docker.sh

# setup() {
#   start_container "simple-single" "192.168.0.2"
# }

# teardown() {
#   stop_container "simple-single"
# }

@test "Start Container" {
  start_container "simple-single" "192.168.0.2"
}

@test "Vip Up" {
  run run_hook "simple-single" "default-single-vip_up" "$(payload default/single/vip_up)"
  echo $output
  [ "$status" -eq 0 ]
}

@test "Vip Down" {
  run run_hook "simple-single" "default-single-vip_down" "$(payload default/single/vip_down)"
  echo $output
  [ "$status" -eq 0 ]
}

@test "Stop Container" {
  stop_container "simple-single"
}