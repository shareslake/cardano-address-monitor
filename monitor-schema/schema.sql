-- Execute "\c cexplorer" before deploying this schema

CREATE SCHEMA address_monitor; -- Create a new schema inside the the cexplorer database

CREATE TABLE address_monitor.config (
   id bool PRIMARY KEY DEFAULT TRUE,
   address VARCHAR NOT NULL,
   k INT NOT NULL,
   CONSTRAINT onerow CHECK (id)
);

-- In the limit case in which there is a soft fork at the block number 'k' and
-- the rollback leaves the table with immutability=k a notification could
-- be duplicated. Adding 1 to 'k' we will never fall to the immutability=k again
INSERT INTO address_monitor.config(address,k) VALUES (:'address', :'k'::INTEGER + 1);

-- We can reference this table as cexplorer.address_monitor.address_tx_in or just address_monitor.address_tx_in when we are inside cexplorer database
CREATE TABLE address_monitor.address_tx_in (
	tx_id BIGINT PRIMARY KEY, -- the transaction Id
	tx_hash VARCHAR(300) UNIQUE NOT NULL,
	tx_out_id BIGINT NOT NULL, -- the tx_out table id
	immutability INT NOT NULL default 0,
	tx_metadata VARCHAR, -- The maximum size for Cardano metadata is 64 bytes, but encoded
	tx_value BIGINT NOT NULL -- output in lovelace
);

-- add a new tx to the address_tx_in table
CREATE OR REPLACE FUNCTION record_tx_received() RETURNS trigger as $$
BEGIN
  IF (NEW.address = (SELECT address FROM address_monitor.config)) THEN
    INSERT INTO address_monitor.address_tx_in(tx_id,tx_hash,tx_metadata,tx_value,tx_out_id) VALUES (
	NEW.tx_id,
        (SELECT hash from tx WHERE NEW.tx_id=id),
	(SELECT json from tx_metadata WHERE NEW.tx_id=tx_id),
	NEW.value,
	NEW.id
    ) ON CONFLICT DO NOTHING;
  END IF;
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Prevent our schema to affect db-sync table updates if it fails
  RAISE WARNING 'There was an error updating the address_monitor.address_tx_in table: %', sqlstate;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- after adding a new block to the block table, all previous Tx need an increase of 1 in the immutability.
CREATE OR REPLACE FUNCTION increase_immutability() RETURNS trigger as $$
BEGIN
  UPDATE address_monitor.address_tx_in SET immutability = immutability + 1;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- When a block is rolled back we decrease immutability of all Tx
CREATE OR REPLACE FUNCTION decrease_tx_immutability() RETURNS trigger as $$
BEGIN
  -- Decrease immutability of all previous tx in one
  UPDATE address_monitor.address_tx_in SET immutability = immutability - 1;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- When a transaction is deleted due to a rollback, we have to remove it from the monitor list.
-- Note it will always be done before being immutable, because a rollback won't happen if it is settled
CREATE OR REPLACE FUNCTION delete_monitor_tx() RETURNS trigger as $$
BEGIN
  DELETE FROM address_monitor.address_tx_in WHERE OLD.tx_id=tx_id;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION notify_tx_immutable() RETURNS trigger as $$
DECLARE
  payload json;
BEGIN
-- send event to the channel called 'monitor'. A NodeJS process will listen events.
-- If the immutability reaches the threshold specified.
  IF (NEW.immutability = (SELECT k FROM address_monitor.config)) THEN
    -- Use the 'address_monitor' channel to notify events
    payload := json_build_object(
	  'tx_hash', NEW.tx_hash,
	  'metadata', NEW.tx_metadata,
	  'value', NEW.tx_value,
	  'multi_asset', (SELECT json_agg(t) FROM (
			SELECT quantity, policy, name FROM ma_tx_out INNER JOIN multi_asset ON multi_asset.id=ma_tx_out.ident AND tx_out_id=NEW.tx_out_id) AS t)
    );
    PERFORM pg_notify('address_monitor', payload::text);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

/* Trigger to notify the channel when a transaction passes the specified inmutability */
/* NOTE: the immutability is specified as the number of blocks over the block containing the Tx */
CREATE OR REPLACE TRIGGER tx_immutable BEFORE UPDATE ON address_monitor.address_tx_in
    FOR EACH ROW
    EXECUTE PROCEDURE notify_tx_immutable();

/* Trigger to increase the immutability of a received Tx with each new block */
CREATE OR REPLACE TRIGGER new_block BEFORE INSERT ON block
    FOR EACH ROW
    EXECUTE PROCEDURE increase_immutability();

/* Triggers to handle rollbacks */
CREATE OR REPLACE TRIGGER block_rollback BEFORE DELETE ON block
    FOR EACH ROW
    EXECUTE PROCEDURE decrease_tx_immutability();
CREATE OR REPLACE TRIGGER tx_rollback BEFORE DELETE ON tx_out
    FOR EACH ROW
    EXECUTE PROCEDURE delete_monitor_tx();

/* Trigger to record transactions received into the address to monitor */
CREATE OR REPLACE TRIGGER tx_received BEFORE INSERT ON tx_out
    FOR EACH ROW
    EXECUTE PROCEDURE record_tx_received();
