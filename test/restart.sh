set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

docker-compose -f test/docker-compose.yaml down -v
docker-compose -f test/docker-compose.yaml up -d

sleep 5

docker-compose -f test/docker-compose.yaml exec shareslake-db-sync psql -Upostgres -dcexplorer -hpostgresql -f /monitor-schema.sql
