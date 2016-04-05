
service_name="MySQL"
default_port=3306

wait_for_running() {
  container=$1
  until docker exec ${container} bash -c "ps aux | grep [m]ysqld"
  do
    sleep 1
  done
}

wait_for_arbitrator_running() {
  container=$1
  until docker exec ${container} bash -c "ps aux | grep [g]arbd"
  do
    sleep 1
  done
}

wait_for_listening() {
  container=$1
  ip=$2
  port=$3
  until docker exec ${container} bash -c "nc ${ip} ${port} < /dev/null"
  do
    sleep 1
  done
}

wait_for_stop() {
  container=$1
  while docker exec ${container} bash -c "ps aux | grep [m]ysqld"
  do
    sleep 1
  done
}

verify_stopped() {
  container=$1
  run docker exec ${container} bash -c "ps aux | grep [m]ysqld"
  echo_lines
  [ "$status" -eq 1 ] 
}

insert_test_data() {
  container=$1
  ip=$2
  port=$3
  key=$4
  data=$5
  run docker exec ${container} bash -c "/data/bin/mysql -u nanobox -ppassword -e 'CREATE TABLE IF NOT EXISTS test_table (id text, value text)' gonano 2> /dev/null"
  echo_lines
  [ "$status" -eq 0 ]
  run docker exec ${container} bash -c "/data/bin/mysql -u nanobox -ppassword -e 'INSERT INTO test_table VALUES ('\"'\"'${key}'\"'\"', '\"'\"'${data}'\"'\"')' gonano 2> /dev/null"
  echo_lines
  [ "$status" -eq 0 ]

}

update_test_data() {
  container=$1
  ip=$2
  port=$3
  key=$4
  data=$5
  run docker exec ${container} bash -c "/data/bin/mysql -u nanobox -ppassword -e 'UPDATE test_table SET value = '\"'\"'${data}'\"'\"' WHERE id = '\"'\"'${key}'\"'\"'' gonano 2> /dev/null"
  echo_lines
  [ "$status" -eq 0 ]
}

verify_test_data() {
  container=$1
  ip=$2
  port=$3
  key=$4
  data=$5
  run docker exec ${container} bash -c "/data/bin/mysql -u nanobox -ppassword -e 'SELECT value FROM test_table WHERE id = '\"'\"'${key}'\"'\"'' gonano 2> /dev/null"
  echo_lines
  [ "${lines[1]}" = "${data}" ]
  [ "$status" -eq 0 ]
}

verify_plan() {
  [ "${lines[0]}"  =  "{" ]
  [ "${lines[1]}"  =  "  \"redundant\": true," ]
  [ "${lines[2]}"  =  "  \"horizontal\": false," ]
  [ "${lines[3]}"  =  "  \"users\": [" ]
  [ "${lines[4]}"  =  "    {" ]
  [ "${lines[5]}"  =  "      \"username\": \"root\"," ]
  [ "${lines[6]}"  =  "      \"meta\": {" ]
  [ "${lines[7]}"  =  "        \"privileges\": [" ]
  [ "${lines[8]}"  =  "          {" ]
  [ "${lines[9]}"  =  "            \"privilege\": \"ALL PRIVILEGES\"," ]
  [ "${lines[10]}" =  "            \"on\": \"*.*\"," ]
  [ "${lines[11]}" =  "            \"with_grant\": true" ]
  [ "${lines[12]}" =  "          }" ]
  [ "${lines[13]}" =  "        ]," ]
  [ "${lines[14]}" =  "        \"databases\": [" ]
  [ "${lines[15]}" =  "        ]" ]
  [ "${lines[16]}" =  "      }" ]
  [ "${lines[17]}" =  "    }," ]
  [ "${lines[18]}" =  "    {" ]
  [ "${lines[19]}" =  "      \"username\": \"nanobox\"," ]
  [ "${lines[20]}" =  "      \"meta\": {" ]
  [ "${lines[21]}" =  "        \"privileges\": [" ]
  [ "${lines[22]}" =  "          {" ]
  [ "${lines[23]}" =  "            \"privilege\": \"ALL PRIVILEGES\"," ]
  [ "${lines[24]}" =  "            \"on\": \"gonano.*\"," ]
  [ "${lines[25]}" =  "            \"with_grant\": true" ]
  [ "${lines[26]}" =  "          }," ]
  [ "${lines[27]}" =  "          {" ]
  [ "${lines[28]}" =  "            \"privilege\": \"PROCESS\"," ]
  [ "${lines[29]}" =  "            \"on\": \"*.*\"," ]
  [ "${lines[30]}" =  "            \"with_grant\": false" ]
  [ "${lines[31]}" =  "          }," ]
  [ "${lines[32]}" =  "          {" ]
  [ "${lines[33]}" =  "            \"privilege\": \"SUPER\"," ]
  [ "${lines[34]}" =  "            \"on\": \"*.*\"," ]
  [ "${lines[35]}" =  "            \"with_grant\": false" ]
  [ "${lines[36]}" =  "          }" ]
  [ "${lines[37]}" =  "        ]," ]
  [ "${lines[38]}" =  "        \"databases\": [" ]
  [ "${lines[39]}" =  "          \"gonano\"" ]
  [ "${lines[40]}" =  "        ]" ]
  [ "${lines[41]}" =  "      }" ]
  [ "${lines[42]}" =  "    }" ]
  [ "${lines[43]}" =  "  ]," ]
  [ "${lines[44]}" =  "  \"ips\": [" ]
  [ "${lines[45]}" =  "    \"default\"" ]
  [ "${lines[46]}" =  "  ]," ]
  [ "${lines[47]}" =  "  \"port\": 3306," ]
  [ "${lines[48]}" =  "  \"behaviors\": [" ]
  [ "${lines[49]}" =  "    \"migratable\"," ]
  [ "${lines[50]}" =  "    \"backupable\"" ]
  [ "${lines[51]}" =  "  ]" ]
  [ "${lines[52]}" =  "}" ]
}