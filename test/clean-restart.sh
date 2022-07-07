set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

set -m

export LD_LIBRARY_PATH="/opt/shareslake/lib"

docker-compose -f test/docker-compose.yaml down -v
rm -Rf ./ledger-state/mainnet

docker-compose -f test/docker-compose.yaml up postgresql -d

sleep 5

PGPASSFILE=./test/pgpass-mainnet ./shareslake-db-sync/scripts/postgresql-setup.sh --createdb

PGPASSFILE=./test/pgpass-mainnet cardano-db-sync --config ./mainnet-config.yaml --socket-path /opt/shareslake/node-ipc/node.sock --state-dir ./ledger-state/mainnet --schema-dir ./shareslake-db-sync/schema/ 2>&1 &

sleep 3
PGPASSFILE=./test/pgpass-mainnet psql -Upostgres -h localhost -p 5432 --dbname cexplorer -f ./monitor-schema/schema.sql

fg

