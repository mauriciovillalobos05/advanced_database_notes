# General Notes

Tables -> structure data
Column (vertical)
ID -> normally primary key to identify a record
Foreign Keys -> references to other tables primary keys.
JOINS -> connecting different tables
INNER JOIN -> only returns what they have in common (select t1.name, t2.name from table1 as t1 INNER JOIN table2 as t2 ON t1.course_id=t2.id)
LEFT JOIN -> everything in common and in addition all of the rest of the elements of table 1.
RIGHT JOIN -> everything in common and in addition all of the rest of the elements of table 2.
FULL JOIN -> all of the data in both tables.
CROSS JOIN -> cartesian product of both tables (returns all combinations)
SELF JOIN -> join in the same table.
Normalization -> process to avoid duplicated data and have a more manageable db.