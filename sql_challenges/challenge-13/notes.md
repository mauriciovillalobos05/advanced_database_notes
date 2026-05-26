OLTP -> few gb
- catpure and proces daily transactions
- recent operational, detailed live data
- reads and mostly writes
- normalized
OLAP -> terabytes
- analyze tendencies and generate reports
- historical data
- mostly reads
- denormalized using star schema

star schema
fact table with joins to multiple dimension tables

fact table
aggregations with foreign keys to the dimension tables

ETL
send data from oltp to olap (Extract, Transform, Load)