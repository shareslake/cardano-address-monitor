set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

export LD_LIBRARY_PATH="/opt/shareslake/lib"

docker-compose -f test/docker-compose.yaml up postgresql -d

sleep 5

#TODO: use nohup to maintain the process running after exiting
PGPASSFILE=./test/pgpass-mainnet cardano-db-sync --config ./mainnet-config.yaml --socket-path /opt/shareslake/node-ipc/node.sock --state-dir ./ledger-state/mainnet --schema-dir ./shareslake-db-sync/schema/

