-- sql bolt part 1
SELECT max(years_employed) FROM employees;
SELECT role, avg(years_employed) FROM employees group by role;
SELECT building, sum(years_employed) FROM employees group by building;

-- sql bolt part 1
SELECT role, count(*) FROM employees where role='Artist';
SELECT role, count(*) FROM employees group by role;
SELECT role, sum(Years_employed) FROM employees where role='Engineer';

-- freesql
select count( distinct shape ) number_of_shapes,
       stddev ( distinct weight ) distinct_weight_stddev
from   bricks;

select shape, sum ( weight ) shape_weight
from   bricks
group by shape;

select shape, sum ( weight )
from   bricks
group  by shape
having sum( weight ) < 4;