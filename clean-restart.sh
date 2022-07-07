set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

set -m

export LD_LIBRARY_PATH="/opt/shareslake/lib"

docker-compose down -v
rm -Rf ./ledger-state/mainnet

docker-compose up postgresql -d

sleep 5

PGPASSFILE=./pgpass-mainnet ./postgresql-setup.sh --createdb

#TODO: use nohup to maintain the process running after exiting
PGPASSFILE=./pgpass-mainnet cardano-db-sync     --config ./mainnet-config.yaml     --socket-path /opt/shareslake/node-ipc/node.sock     --state-dir ./ledger-state/mainnet     --schema-dir ./schema/ > ./db-sync.log 2>&1 &

sleep 3
PGPASSFILE=./pgpass-mainnet psql -Upostgres -h localhost -p 5432 --dbname cexplorer -a -f schema.sql

fg

