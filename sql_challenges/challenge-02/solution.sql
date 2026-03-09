-- problem 6
SELECT movies.title, box_office.Domestic_sales, box_office.International_sales FROM movies JOIN Boxoffice as box_office ON movies.id=box_office.Movie_id;
SELECT movies.title, box_office.Domestic_sales, box_office.International_sales FROM movies JOIN Boxoffice as box_office ON movies.id=box_office.Movie_id where box_office.International_sales> box_office.Domestic_sales;
SELECT movies.title, box_office.rating FROM movies JOIN Boxoffice as box_office ON movies.id=box_office.Movie_id order by box_office.rating DESC;

-- problem 7
SELECT DISTINCT Building_name FROM Buildings as b JOIN Employees as e on b.Building_name=e.Building;
SELECT b.Building_name, b.capacity FROM Buildings as b;
SELECT DISTINCT b.Building_name, e.Role FROM Buildings as b LEFT JOIN Employees as e on b.Building_name=e.Building;

-- data lemur
SELECT p.page_id FROM pages as p LEFT JOIN page_likes as l ON p.page_id=l.page_id where l.liked_date is NULL order by p.page_id asc;