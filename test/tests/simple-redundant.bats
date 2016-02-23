# source docker helpers
. util/docker.sh

echo_lines() {
  for (( i=0; i < ${#lines[*]}; i++ ))
  do
    echo ${lines[$i]}
  done
}

# Start containers
@test "Start Primary Container" {
  start_container "simple-redundant-primary" "192.168.0.2"
}

@test "Start Secondary Container" {
  start_container "simple-redundant-secondary" "192.168.0.3"
}

@test "Start Monitor Container" {
  start_container "simple-redundant-monitor" "192.168.0.4"
}

# Configure containers
@test "Configure Primary Container" {
  run run_hook "simple-redundant-primary" "default-configure" "$(payload default/configure-production)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Configure Secondary Container" {
  run run_hook "simple-redundant-secondary" "default-configure" "$(payload default/configure-production)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Configure Monitor Container" {
  run run_hook "simple-redundant-monitor" "monitor-configure" "$(payload monitor/configure)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Stop Primary MySQL" {
  run run_hook "simple-redundant-primary" "default-stop" "$(payload default/stop)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Stop Secondary MySQL" {
  run run_hook "simple-redundant-secondary" "default-stop" "$(payload default/stop)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Redundant Configure Primary Container" {
  run run_hook "simple-redundant-primary" "default-redundant-configure" "$(payload default/redundant/configure-primary)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Redundant Configure Secondary Container" {
  run run_hook "simple-redundant-secondary" "default-redundant-configure" "$(payload default/redundant/configure-secondary)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Redundant Configure Monitor Container" {
  run run_hook "simple-redundant-monitor" "monitor-redundant-configure" "$(payload monitor/redundant/configure)"
  echo_lines
  [ "$status" -eq 0 ]
}

# @test "Redundant Configure VIP Agent Primary Container" {
#   run run_hook "simple-redundant-primary" "default-redundant-config_vip_agent" "$(payload default/redundant/config_vip_agent-primary)"
#   echo_lines
#   [ "$status" -eq 0 ]
# }

# @test "Redundant Configure VIP Agent Secondary Container" {
#   run run_hook "simple-redundant-secondary" "default-redundant-config_vip_agent" "$(payload default/redundant/config_vip_agent-secondary)"
#   echo_lines
#   [ "$status" -eq 0 ]
# }

# @test "Redundant Configure VIP Agent Monitor Container" {
#   run run_hook "simple-redundant-monitor" "monitor-redundant-config_vip_agent" "$(payload monitor/redundant/config_vip_agent-monitor)"
#   echo_lines
#   [ "$status" -eq 0 ]
# }

@test "Ensure MySQL Is Stopped" {
  while docker exec "simple-redundant-primary" bash -c "ps aux | grep [m]ysqld"
  do
    sleep 1
  done
  while docker exec "simple-redundant-secondary" bash -c "ps aux | grep [m]ysqld"
  do
    sleep 1
  done
}

@test "Start Primary MySQL" {
  run run_hook "simple-redundant-primary" "default-start" "$(payload default/start)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Ensure MySQL Primary Is Started" {
  until docker exec "simple-redundant-primary" bash -c "ps aux | grep [m]ysqld"
  do
    sleep 1
  done
  until docker exec "simple-redundant-primary" bash -c "nc 192.168.0.2 3306 < /dev/null"
  do
    sleep 1
  done
}

@test "Start Secondary MySQL" {
  run run_hook "simple-redundant-secondary" "default-start" "$(payload default/start)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Ensure MySQL Secondary Is Started" {
  until docker exec "simple-redundant-secondary" bash -c "ps aux | grep [m]ysqld"
  do
    sleep 1
  done
  until docker exec "simple-redundant-secondary" bash -c "nc 192.168.0.3 3306 < /dev/null"
  do
    sleep 1
  done
}

@test "Start Monitor Garbd" {
  run run_hook "simple-redundant-monitor" "monitor-start" "$(payload monitor/start)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Ensure Monitor Garbd Is Started" {
  until docker exec "simple-redundant-monitor" bash -c "ps aux | grep [g]arbd"
  do
    sleep 1
  done
}

@test "Insert Primary MySQL Data" {
  run docker exec "simple-redundant-primary" bash -c "/data/bin/mysql -u gonano -ppassword -e 'CREATE TABLE test_table (id INT(64) AUTO_INCREMENT PRIMARY KEY, value INT(64))' gonano"
  echo_lines
  [ "$status" -eq 0 ]
  run docker exec "simple-redundant-primary" bash -c "/data/bin/mysql -u gonano -ppassword -e 'INSERT INTO test_table VALUES (1, 1)' gonano"
  echo_lines
  [ "$status" -eq 0 ]
  run docker exec "simple-redundant-primary" bash -c "/data/bin/mysql -u gonano -ppassword -e 'SELECT * FROM test_table' gonano"
  echo_lines
  [ "${lines[1]}" = "1	1" ]
  [ "$status" -eq 0 ]
}

@test "Insert Secondary MySQL Data" {
  run docker exec "simple-redundant-secondary" bash -c "/data/bin/mysql -u gonano -ppassword -e 'INSERT INTO test_table VALUES (2, 2)' gonano"
  echo_lines
  [ "$status" -eq 0 ]
  run docker exec "simple-redundant-secondary" bash -c "/data/bin/mysql -u gonano -ppassword -e 'SELECT * FROM test_table' gonano"
  echo_lines
  [ "${lines[1]}" = "1	1" ]
  [ "${lines[2]}" = "2	2" ]
  [ "$status" -eq 0 ]
}

@test "Verify Primary MySQL Data" {
  run docker exec "simple-redundant-primary" bash -c "/data/bin/mysql -u gonano -ppassword -e 'SELECT * FROM test_table' gonano"
  echo_lines
  [ "${lines[1]}" = "1	1" ]
  [ "${lines[2]}" = "2	2" ]
  [ "$status" -eq 0 ]
}

# @test "Start Primary VIP Agent" {
#   run run_hook "simple-redundant-primary" "default-redundant-start_vip_agent" "$(payload default/redundant/start_vip_agent)"
#   echo_lines
#   [ "$status" -eq 0 ]
# }

# @test "Start Secondary VIP Agent" {
#   run run_hook "simple-redundant-secondary" "default-redundant-start_vip_agent" "$(payload default/redundant/start_vip_agent)"
#   echo_lines
#   [ "$status" -eq 0 ]
# }

# @test "Start Monitor VIP Agent" {
#   run run_hook "simple-redundant-monitor" "monitor-redundant-start_vip_agent" "$(payload monitor/redundant/start_vip_agent)"
#   echo_lines
#   [ "$status" -eq 0 ]
# }

# Stop containers
@test "Stop Primary Container" {
  stop_container "simple-redundant-primary" "192.168.0.2"
}

@test "Stop Secondary Container" {
  stop_container "simple-redundant-secondary" "192.168.0.3"
}

@test "Stop Monitor Container" {
  stop_container "simple-redundant-monitor" "192.168.0.3"
}