
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
  until docker exec ${container} bash -c "nc -q 1 ${ip} ${port} < /dev/null"
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
  sleep 1
  run docker exec ${container} bash -c "/data/bin/mysql -u nanobox -ppassword -e 'SELECT value FROM test_table WHERE id = '\"'\"'${key}'\"'\"'' gonano 2> /dev/null"
  echo_lines
  [ "${lines[1]}" = "${data}" ]
  [ "$status" -eq 0 ]
}

verify_plan() {

  expected=$(cat <<-END
{
  "redundant": false,
  "horizontal": false,
  "user": "nanobox",
  "users": [
    {
      "username": "root",
      "meta": {
        "privileges": [
          {
            "privilege": "ALL PRIVILEGES",
            "on": "*.*",
            "with_grant": true
          }
        ],
        "databases": [

        ]
      }
    },
    {
      "username": "nanobox",
      "meta": {
        "privileges": [
          {
            "privilege": "ALL PRIVILEGES",
            "on": "gonano.*",
            "with_grant": true
          },
          {
            "privilege": "PROCESS",
            "on": "*.*",
            "with_grant": false
          },
          {
            "privilege": "SUPER",
            "on": "*.*",
            "with_grant": false
          }
        ],
        "databases": [
          "gonano"
        ]
      }
    }
  ],
  "ips": [
    "default"
  ],
  "port": 3306,
  "behaviors": [
    "migratable",
    "backupable"
  ]
}
END)

  [ "$output" = "$expected" ]
}