# Cardano Address Monitor

Monitor one or more Cardano addresses and subscribe to events containing information about the received transactions.

The Cardano Address Monitor ensures you won't process a transaction twice.

# How does it work?

The monitor embeeds an schema into the cardano-db-sync's PostgreSQL database.

The schema contains logic that monitor the transactions received by the specified addresses.

Once the received transaction is considered immutable, the monitor will send an event into a PosgtreSQL channel.
A transaction is immutable when there are `k` blocks added on top of the block containing the transaction. `k` is the Cardano security parameter.

Since different applications can consider a different probability of being immutable, you can configure `k` for the monitor, i.e. you can configure how many blocks must be added on top of the block containing a transaction before the monitor sends the event. By default it is `2160`.

# Avoid duplicated events

The monitor won't send any duplicated event. Nevertheless, you may be carefull when restarting cardano-db-sync if you delete the `ledger-state` folder.

You will obtain duplicated events if:

* You delete the schema embeeded by the monitor (`address_monitor`) or the content of the tables.

* You manually decrease the `immutability` colum of the table `address_monitor.address_tx_in`.

> IMPORTANT: if your cardano-db-sync crashes for some reason and you need to deploy a new clean instance, be sure to backup the data under `address_monitor` schema so you can avoid duplicated events.

# Installation

## Installing into an already running cardano-db-sync instance

1.
1.

# Installing both cardano-db-sync and Cardano Address Monitor

1.
1.

# Configuring the network

## Shareslake mainnet

## Cardano mainnet

## Cardano testnet

## Custom testnet

# Testing

1. Run `clean-install.sh`
1. Run `tail -f db-sync.sql` to see db-sync logs
1. Run `cd listener && node index.js` to run the example listener.

When a transaction is sent to the monitored address, the example listener will show its content.

# TODO

[ ] Support configuration of `k` and addresses from another table.
[ ] Support Cardano and Shareslake networks.
[ ] Remove hardcoded paths for Shareslake node.




