# Transactions

* Client making CRUD requests to our db.
* To avoid race conditions, we can add locks to update the db and provide serializability.
* We also need to provide atomicity, so all the updates in a transaction should be treated as one, so all should succeed or all should fail.
* We have other properties such as consistency (moving from one state to another), Isolation (serializability), and Durability (data survives crashes and restarts).
* Autocommit is a database setting that controls whether each SQL statement is automatically treated as its own transaction.
* A savepoint is like a checkpoint inside a transaction that lets you roll back part of the work without canceling the entire transaction.