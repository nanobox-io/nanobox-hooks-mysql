# source docker helpers
. util/docker.sh

echo_lines() {
  for (( i=0; i < ${#lines[*]}; i++ ))
  do
    echo ${lines[$i]}
  done
}

@test "Start Local Container" {
  start_container "simple-single-local" "192.168.0.2"
}

@test "Configure Local Container" {
  run run_hook "simple-single-local" "default-configure" "$(payload default/configure-local)"
  echo_lines
  [ "$status" -eq 0 ] 
}

@test "Start Local MySQL" {
  run run_hook "simple-single-local" "default-start" "$(payload default/start)"
  echo_lines
  [ "$status" -eq 0 ]
  # Verify
  run docker exec simple-single-local bash -c "ps aux | grep [m]ysqld"
  echo_lines
  [ "$status" -eq 0 ]
  until docker exec "simple-single-local" bash -c "nc 192.168.0.2 3306 < /dev/null"
  do
    sleep 1
  done
}

@test "Insert Local MySQL Data" {
  run docker exec "simple-single-local" bash -c "/data/bin/mysql -u gonano -ppassword -e 'CREATE TABLE test_table (id INT(64) AUTO_INCREMENT PRIMARY KEY, value INT(64))' gonano 2> /dev/null"
  echo_lines
  [ "$status" -eq 0 ]
  run docker exec "simple-single-local" bash -c "/data/bin/mysql -u gonano -ppassword -e 'INSERT INTO test_table VALUES (1, 1)' gonano 2> /dev/null"
  echo_lines
  [ "$status" -eq 0 ]
  run docker exec "simple-single-local" bash -c "/data/bin/mysql -u gonano -ppassword -e 'SELECT * FROM test_table' gonano 2> /dev/null"
  echo_lines
  [ "${lines[1]}" = "1	1" ]
  [ "$status" -eq 0 ]
}

@test "Stop Local MySQL" {
  run run_hook "simple-single-local" "default-stop" "$(payload default/stop)"
  echo_lines
  [ "$status" -eq 0 ]
  while docker exec "simple-single-local" bash -c "ps aux | grep [m]ysqld"
  do
    sleep 1
  done
  # Verify
  run docker exec simple-single-local bash -c "ps aux | grep [m]ysqld"
  echo_lines
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
  echo_lines
  [ "$status" -eq 0 ] 
}

@test "Start Production MySQL" {
  run run_hook "simple-single-production" "default-start" "$(payload default/start)"
  echo_lines
  [ "$status" -eq 0 ]
  # Verify
  run docker exec simple-single-production bash -c "ps aux | grep [m]ysqld"
  echo_lines
  [ "$status" -eq 0 ]
  until docker exec "simple-single-production" bash -c "nc 192.168.0.2 3306 < /dev/null"
  do
    sleep 1
  done
}

@test "Insert Production MySQL Data" {
  run docker exec "simple-single-production" bash -c "/data/bin/mysql -u gonano -ppassword -e 'CREATE TABLE test_table (id INT(64) AUTO_INCREMENT PRIMARY KEY, value INT(64))' gonano 2> /dev/null"
  echo_lines
  [ "$status" -eq 0 ]
  run docker exec "simple-single-production" bash -c "/data/bin/mysql -u gonano -ppassword -e 'INSERT INTO test_table VALUES (1, 1)' gonano 2> /dev/null"
  echo_lines
  [ "$status" -eq 0 ]
  run docker exec "simple-single-production" bash -c "/data/bin/mysql -u gonano -ppassword -e 'SELECT * FROM test_table' gonano 2> /dev/null"
  echo_lines
  [ "${lines[1]}" = "1	1" ]
  [ "$status" -eq 0 ]
}

@test "Stop Production MySQL" {
  run run_hook "simple-single-production" "default-stop" "$(payload default/stop)"
  echo_lines
  [ "$status" -eq 0 ]
  while docker exec "simple-single-production" bash -c "ps aux | grep [m]ysqld"
  do
    sleep 1
  done
  # Verify
  run docker exec simple-single-production bash -c "ps aux | grep [m]ysqld"
  echo_lines
  [ "$status" -eq 1 ] 
}

@test "Stop Production Container" {
  stop_container "simple-single-production"
}