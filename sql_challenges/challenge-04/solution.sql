-- free sql

-- Complete the following query to return the count and average weight of bricks for each shape:
select b.*,
       count(*) over (
         partition by SHAPE
       ) bricks_per_shape,
       median ( weight ) over (
         partition by SHAPE
       ) median_weight_per_shape
from   bricks b
order  by shape, weight, brick_id;

-- Complete the following query to get the running average weight, ordered by brick_id:
select b.brick_id, b.weight,
       round ( avg ( weight ) over (
         order by BRICK_ID
       ), 2 ) running_average_weight
from   bricks b
order  by brick_id;

-- Complete the windowing clauses to return:

-- The minimum colour of the two rows before (but not including) the current row
-- The count of rows with the same weight as the current and one value following

select b.*,
       min ( colour ) over (
         order by brick_id
         rows between 2 preceding and 1 preceding
       ) first_colour_two_prev,
       count (*) over (
         order by weight
         range between current row and 1 following
       ) count_values_this_and_next
from   bricks b
order  by weight;

-- Complete the following query to find the rows where

-- The total weight for the shape
-- The running weight by brick_id

with totals as (
  select b.*,
         sum ( weight ) over (
           partition by b.SHAPE
         ) weight_per_shape,
         sum ( weight ) over (
           order by b.BRICK_ID
         ) running_weight_by_id
  from   bricks b
)
select * from totals
where  weight_per_shape > 4 and running_weight_by_id>4
order  by brick_id


-- data lemur 
SELECT department_name, name, salary
FROM (
    SELECT 
        d.department_name,
        e.name,
        e.salary,
        DENSE_RANK() OVER (
            PARTITION BY d.department_id
            ORDER BY e.salary DESC
        ) AS rn
    FROM employee e
    JOIN department d 
        ON e.department_id = d.department_id
) ranked
WHERE rn <= 3
ORDER BY department_name, salary DESC, name;