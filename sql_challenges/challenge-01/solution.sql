--lesson 1
SELECT Title FROM movies;
SELECT Director FROM movies;
SELECT Title, Director Year FROM movies;
SELECT Title, Year FROM movies;
SELECT * FROM movies;

--lesson 2
SELECT * FROM Movies where id=6;
SELECT * FROM Movies where Year>=2000 and Year<=2010;
SELECT * FROM Movies where Year NOT BETWEEN 2000 and 2010;
SELECT * FROM Movies order by Year ASC limit 5;

--lesson 3
SELECT * FROM movies where Title LIKE "Toy Story%";
SELECT * FROM movies where director="John Lasseter";
SELECT * FROM movies where director!="John Lasseter";
SELECT * FROM movies where Title LIKE "WALL-%";

--lesson 4
SELECT DISTINCT director FROM movies order by Director;
SELECT * FROM movies order by Year DESC Limit 4;
SELECT * FROM movies order by title ASC Limit 5;
SELECT * FROM movies order by title ASC Limit 5 offset 5;

--lesson 5
SELECT City, Population FROM north_american_cities where Country="Canada";
SELECT * FROM north_american_cities where Country="United States" order by latitude desc;
SELECT * FROM north_american_cities where Longitude<-87.629798 order by longitude;
SELECT * FROM north_american_cities where country="Mexico" order by population desc limit 2;
SELECT * FROM north_american_cities where country="United States" order by population desc limit 2 offset 2;