set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

docker-compose -f test/docker-compose.yaml down -v
docker-compose -f test/docker-compose.yaml up -d

sleep 5

docker-compose -f test/docker-compose.yaml exec shareslake-db-sync psql -v address="addr1q8u8yjqrk92f85fdhmv8de8xlusfay4vms6u2mar09sr7d7yhlettkjsqaqtkn8mnmaq6ng9nujzd5ng49m3t6ph2s5qqmvu4c" -v k=2160 -Upostgres -dcexplorer -hpostgresql -f /monitor-schema.sql
