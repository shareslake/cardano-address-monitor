# Cardano Address Monitor

Monitor one or more Cardano addresses for transactions and receive events with the transactions information. Designed to avoid processing a transaction twice.

# How does it work?

When a transaction received by specified addresses is considered immutable the monitor sends an event into a PosgtreSQL channel. You can subscribe to the PostgreSQL channel to receive the events. The events contain information about the transactions received.

A transaction is immutable when there are `k` blocks added on top of the block containing the transaction. `k` is the Cardano security parameter.
Since different applications can consider a different probability of being immutable, you can configure `k` for the monitor, i.e. you can configure how many blocks must be added on top of the block containing a transaction before the monitor sends the event. By default it is `2160`.

# Installation

The address monitor is installed just by deploying a PostgreSQL schema in the same database that cardano-db-sync uses.

## Installing into an already running cardano-db-sync instance

```console
psql -U<user> -d<database> -h<host> -f ./monitor-schema/schema.sql -v address='<address>' -v k=2160
```

> The database name must be the database used by cardano-db-sync. It is usually called `cexplorer`.


## Install a full stack with docker-compose

> Executing the restart script deletes the PostgreSQL volume

You may need to change the ownership of `test/pgpass-mainnet` and `test/ledger-state/mainnet` to belong to user `1001`.

```console
./test/restart.sh
```

The bove command will use `test/docker-compose.yaml` to deploy a Shareslake node, shareslake-db-sync, postgresql and install the monitor.
You can edit the docker-compose images and substitute the configuration and genesis files under `test` to deploy a Cardano mainnet node instead.

> NOTE: shareslake-db-sync is the same as cardano-db-sync but used to connect to the Shareslake network instead of Cardano mainnet.

# Check installation

Subscribe with the example NodeJS listener to watch events. You can take the file as a base to build your custom scripts:

```console
cd listener && node index.js
```

It will just listen events and log them.

# Listening events

You can listen events just by subscribing to the `address_monitor` channel in PostgreSQL.

# Avoid duplicated events

As far as you don't delete data from PostgreSQL, an even't should never be send twice.

# TODO

[ ] Support for multiple addresses.
[ ] Support configuration of `k` and addresses from another table.
