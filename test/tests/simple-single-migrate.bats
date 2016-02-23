# source docker helpers
. util/docker.sh

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
  until docker exec "simple-single-old" bash -c "nc 192.168.0.2 3306 < /dev/null"
  do
    sleep 1
  done
}

@test "Insert Old MySQL Data" {
  run docker exec "simple-single-old" bash -c "/data/bin/mysql -u gonano -ppassword -e 'CREATE TABLE test_table (id INT(64) AUTO_INCREMENT PRIMARY KEY, value INT(64))' gonano"
  echo_lines
  [ "$status" -eq 0 ]
  run docker exec "simple-single-old" bash -c "/data/bin/mysql -u gonano -ppassword -e 'INSERT INTO test_table VALUES (1, 1)' gonano"
  echo_lines
  [ "$status" -eq 0 ]
  run docker exec "simple-single-old" bash -c "/data/bin/mysql -u gonano -ppassword -e 'SELECT * FROM test_table' gonano"
  echo_lines
  [ "${lines[1]}" = "1	1" ]
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

@test "Update Old MySQL Data" {
  run docker exec "simple-single-old" bash -c "/data/bin/mysql -u gonano -ppassword -e 'UPDATE test_table SET value = 2 WHERE id = 1' gonano"
  echo_lines
  [ "$status" -eq 0 ]
  run docker exec "simple-single-old" bash -c "/data/bin/mysql -u gonano -ppassword -e 'SELECT * FROM test_table' gonano"
  echo_lines
  [ "${lines[1]}" = "1	2" ]
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
  until docker exec "simple-single-new" bash -c "nc 192.168.0.3 3306 < /dev/null"
  do
    sleep 1
  done
}

@test "Verify New MySQL Data" {
  run docker exec "simple-single-new" bash -c "/data/bin/mysql -u gonano -ppassword -e 'SELECT * FROM test_table' gonano"
  echo_lines
  [ "${lines[1]}" = "1	2" ]
  [ "$status" -eq 0 ]
}

@test "Stop Old Container" {
  stop_container "simple-single-old"
}

@test "Stop New Container" {
  stop_container "simple-single-new"
}