# Test mysql after build
set -e
docker run --name=mysql-test -d nanobox/mysql
docker exec -it mysql-test /bin/bash
curl localhost:5540/hooks/configure -d '{"logtap_host":"10.0.2.15:6361","uid":"db1"}'
sleep 2
mysql -u nanobox -ppassword gonano -e 'show databases;'
exit
docker kill mysql-test
docker rm mysql-test
