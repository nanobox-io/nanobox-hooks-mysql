# source docker helpers
. util/docker.sh

setup() {
  start_container "simple-single" "192.168.0.2"
}

teardown() {
  stop_container "simple-single"
}

@test "simple-single-environment" {
  run run_hook "simple-single" "environment" "$(payload simple-single)"

  [ "$status" -eq 0 ]

  [ "${lines[0]}" = "{" ]
  [ "${lines[1]}" = "  \"HOST\": \"192.168.0.2\"," ]
  [ "${lines[2]}" = "  \"PORT\": \"3306\"," ]
  [ "${lines[3]}" = "  \"USER\": \"nanobox\"," ]
  [ "${lines[4]}" = "  \"PASS\": \"password\"," ]
  [ "${lines[5]}" = "  \"NAME\": \"gonano\"" ]
  [ "${lines[6]}" = "}" ]
}