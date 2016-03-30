# source docker helpers
. util/docker.sh

echo_lines() {
  for (( i=0; i < ${#lines[*]}; i++ ))
  do
    echo ${lines[$i]}
  done
}

# Start containers
@test "Start Old Containers" {
  start_container "simple-redundant-old-primary" "192.168.0.2"
  start_container "simple-redundant-old-secondary" "192.168.0.3"
  start_container "simple-redundant-old-monitor" "192.168.0.4"
}

@test "Start New Containers" {
  start_container "simple-redundant-new-primary" "192.168.0.6"
  start_container "simple-redundant-new-secondary" "192.168.0.7"
  start_container "simple-redundant-new-monitor" "192.168.0.8"
}

# Configure containers
@test "Configure Old Containers" {
  run run_hook "simple-redundant-old-primary" "default-configure" "$(payload default/configure-production)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-secondary" "default-configure" "$(payload default/configure-production)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-monitor" "monitor-configure" "$(payload monitor/configure)"
  echo_lines
  [ "$status" -eq 0 ]
}

# Configure containers
@test "Configure New Containers" {
  run run_hook "simple-redundant-new-primary" "default-configure" "$(payload default/configure-production)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-new-secondary" "default-configure" "$(payload default/configure-production)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-new-monitor" "monitor-configure" "$(payload monitor/configure)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Stop Old MySQLs" {
  run run_hook "simple-redundant-old-primary" "default-stop" "$(payload default/stop)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-secondary" "default-stop" "$(payload default/stop)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Stop New MySQLs" {
  run run_hook "simple-redundant-new-primary" "default-stop" "$(payload default/stop)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-new-secondary" "default-stop" "$(payload default/stop)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Redundant Configure Old Containers" {
  run run_hook "simple-redundant-old-primary" "default-redundant-configure" "$(payload default/redundant/configure-primary)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-secondary" "default-redundant-configure" "$(payload default/redundant/configure-secondary)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-monitor" "monitor-redundant-configure" "$(payload monitor/redundant/configure)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Redundant Configure New Containers" {
  run run_hook "simple-redundant-new-primary" "default-redundant-configure" "$(payload default/redundant/configure-primary-new)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-new-secondary" "default-redundant-configure" "$(payload default/redundant/configure-secondary-new)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-new-monitor" "monitor-redundant-configure" "$(payload monitor/redundant/configure-new)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Ensure Old MySQLs Are Stopped" {
  while docker exec "simple-redundant-old-primary" bash -c "ps aux | grep [m]ysqld"
  do
    sleep 1
  done
  while docker exec "simple-redundant-old-secondary" bash -c "ps aux | grep [m]ysqld"
  do
    sleep 1
  done
}

@test "Start Old MySQL Cluster" {
  run run_hook "simple-redundant-old-primary" "default-start" "$(payload default/start)"
  echo_lines
  [ "$status" -eq 0 ]
  until docker exec "simple-redundant-old-primary" bash -c "ps aux | grep [m]ysqld"
  do
    sleep 1
  done
  until docker exec "simple-redundant-old-primary" bash -c "nc 192.168.0.2 3306 < /dev/null"
  do
    sleep 1
  done
  run run_hook "simple-redundant-old-secondary" "default-start" "$(payload default/start)"
  echo_lines
  [ "$status" -eq 0 ]
  until docker exec "simple-redundant-old-secondary" bash -c "ps aux | grep [m]ysqld"
  do
    sleep 1
  done
  until docker exec "simple-redundant-old-secondary" bash -c "nc 192.168.0.3 3306 < /dev/null"
  do
    sleep 1
  done
  run run_hook "simple-redundant-old-monitor" "monitor-start" "$(payload monitor/start)"
  echo_lines
  [ "$status" -eq 0 ]
  until docker exec "simple-redundant-old-monitor" bash -c "ps aux | grep [g]arbd"
  do
    sleep 1
  done
}

@test "Ensure New MySQLs Are Stopped" {
  while docker exec "simple-redundant-new-primary" bash -c "ps aux | grep [m]ysqld"
  do
    sleep 1
  done
  while docker exec "simple-redundant-new-secondary" bash -c "ps aux | grep [m]ysqld"
  do
    sleep 1
  done
}

@test "Start New SSHD" {
  # start ssh server
  run run_hook "simple-redundant-new-primary" "default-start_sshd" "$(payload default/start_sshd)"
  echo_lines
  [ "$status" -eq 0 ]
  # start ssh server
  run run_hook "simple-redundant-new-secondary" "default-start_sshd" "$(payload default/start_sshd)"
  echo_lines
  [ "$status" -eq 0 ]
  until docker exec "simple-redundant-new-primary" bash -c "ps aux | grep [s]shd"
  do
    sleep 1
  done
  until docker exec "simple-redundant-new-secondary" bash -c "ps aux | grep [s]shd"
  do
    sleep 1
  done
}

@test "Insert Old MySQL Data" {
  run docker exec "simple-redundant-old-primary" bash -c "/data/bin/mysql -u gonano -ppassword -e 'CREATE TABLE test_table (id INT(64) AUTO_INCREMENT PRIMARY KEY, value INT(64))' gonano 2> /dev/null"
  echo_lines
  [ "$status" -eq 0 ]
  run docker exec "simple-redundant-old-primary" bash -c "/data/bin/mysql -u gonano -ppassword -e 'INSERT INTO test_table VALUES (1, 1)' gonano 2> /dev/null"
  echo_lines
  [ "$status" -eq 0 ]
  run docker exec "simple-redundant-old-primary" bash -c "/data/bin/mysql -u gonano -ppassword -e 'SELECT * FROM test_table' gonano 2> /dev/null"
  echo_lines
  [ "${lines[1]}" = "1	1" ]
  [ "$status" -eq 0 ]
}

@test "Redundant Old Pre-Export" {
  run run_hook "simple-redundant-old-primary" "default-redundant-pre_export" "$(payload default/redundant/pre_export)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Insert Secondary MySQL Data" {
  run docker exec "simple-redundant-old-secondary" bash -c "/data/bin/mysql -u gonano -ppassword -e 'INSERT INTO test_table VALUES (2, 2)' gonano 2> /dev/null"
  echo_lines
  [ "$status" -eq 0 ]
  run docker exec "simple-redundant-old-secondary" bash -c "/data/bin/mysql -u gonano -ppassword -e 'SELECT * FROM test_table' gonano 2> /dev/null"
  echo_lines
  [ "${lines[1]}" = "1	1" ]
  [ "${lines[2]}" = "2	2" ]
  [ "$status" -eq 0 ]
}

@test "Restop Old MySQLs" {
  run run_hook "simple-redundant-old-primary" "default-stop" "$(payload default/stop)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-secondary" "default-stop" "$(payload default/stop)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Ensure Old MySQLs Are Stopped" {
  while docker exec "simple-redundant-old-primary" bash -c "ps aux | grep [m]ysqld"
  do
    sleep 1
  done
  while docker exec "simple-redundant-old-secondary" bash -c "ps aux | grep [m]ysqld"
  do
    sleep 1
  done
}

@test "Redundant Old Export" {
  run run_hook "simple-redundant-old-primary" "default-redundant-export" "$(payload default/redundant/export)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Stop New SSHD" {
  # stop ssh server
  run run_hook "simple-redundant-new-primary" "default-stop_sshd" "$(payload default/stop_sshd)"
  echo_lines
  [ "$status" -eq 0 ]
  # stop ssh server
  run run_hook "simple-redundant-new-secondary" "default-stop_sshd" "$(payload default/stop_sshd)"
  echo_lines
  [ "$status" -eq 0 ]
  while docker exec "simple-redundant-new-primary" bash -c "ps aux | grep [s]shd"
  do
    sleep 1
  done
  while docker exec "simple-redundant-new-secondary" bash -c "ps aux | grep [s]shd"
  do
    sleep 1
  done
}
@test "Start New MySQL Cluster" {
  run run_hook "simple-redundant-new-primary" "default-start" "$(payload default/start)"
  echo_lines
  [ "$status" -eq 0 ]
  until docker exec "simple-redundant-new-primary" bash -c "ps aux | grep [m]ysqld"
  do
    sleep 1
  done
  until docker exec "simple-redundant-new-primary" bash -c "nc 192.168.0.6 3306 < /dev/null"
  do
    sleep 1
  done
  run run_hook "simple-redundant-new-secondary" "default-start" "$(payload default/start)"
  echo_lines
  [ "$status" -eq 0 ]
  until docker exec "simple-redundant-new-secondary" bash -c "ps aux | grep [m]ysqld"
  do
    sleep 1
  done
  until docker exec "simple-redundant-new-secondary" bash -c "nc 192.168.0.7 3306 < /dev/null"
  do
    sleep 1
  done
  run run_hook "simple-redundant-new-monitor" "monitor-start" "$(payload monitor/start)"
  echo_lines
  [ "$status" -eq 0 ]
  until docker exec "simple-redundant-new-monitor" bash -c "ps aux | grep [g]arbd"
  do
    sleep 1
  done
}

@test "Verify New MySQL Data" {
  run docker exec "simple-redundant-new-primary" bash -c "/data/bin/mysql -u gonano -ppassword -e 'SELECT * FROM test_table' gonano 2> /dev/null"
  echo_lines
  [ "${lines[1]}" = "1	1" ]
  [ "${lines[2]}" = "2	2" ]
  [ "$status" -eq 0 ]
}

# Stop containers
@test "Stop Old Containers" {
  stop_container "simple-redundant-old-primary"
  stop_container "simple-redundant-old-secondary"
  stop_container "simple-redundant-old-monitor"
}

@test "Stop New Containers" {
  stop_container "simple-redundant-new-primary"
  stop_container "simple-redundant-new-secondary"
  stop_container "simple-redundant-new-monitor"
}