WITH rent_billed AS (
SELECT
l.id AS location_id,
l.name As location_name,
SUM(s.rent_per_month) AS rent_billed,
COALESCE(SUM(s.arrears), 0) AS total_arrears
FROM cleaned_leases s
LEFT JOIN cleaned_units u ON u.id = s.unit_id
LEFT JOIN cleaned_property p ON p.cl = u.property_id
LEFT JOIN cleaned_locations l ON l.id = p.location_id
WHERE s.valid_lease = 1
GROUP BY l.id, l.name
)
SELECT
location_id,
location_name,
rent_billed,
total_arrears
FROM rent_billed;

WITH occupancy_rate AS (
SELECT
p.cl AS property_id,
p.name AS property_name,
COUNT(DISTINCT u.id) AS total_units,
COUNT(DISTINCT CASE WHEN valid_lease = 1 THEN u.id END) AS occupied_units
FROM cleaned_property p
LEFT JOIN cleaned_units u ON p.cl = u.property_id
LEFT JOIN cleaned_leases s ON s.unit_id = u.id
GROUP BY p.cl, p.name
)
SELECT
property_id,
Property_name,
ROUND((occupied_units * 100 / NULLIF(total_units,0)),2) AS
occupancy_rate
FROM occupancy_rate;

WITH properties_arrears AS (
SELECT
p.cl AS property_id,
P.name AS property_name,
SUM(arrears) as total_arrears
FROM cleaned_leases s
LEFT JOIN cleaned_units u ON u.id = s.unit_id
LEFT JOIN cleaned_property p ON p.cl = u.property_id
GROUP BY p.cl, p.name
)

SELECT
property_id,
property_name,
total_arrears
FROM properties_arrears
ORDER BY total_arrears DESC
LIMIT 3;

WITH average_month_rent AS (
SELECT
p.name AS property_name,
l.name AS location_name,
AVG(s.rent_per_month) AS average_monthly_rent
FROM cleaned_property p
LEFT JOIN cleaned_units u ON u.property_id = p.cl
LEFT JOIN cleaned_leases s ON s.unit_id = u.id
LEFT JOIN cleaned_locations l ON l.id = p.location_id
GROUP BY p.cl, p.name, l.name
)
SELECT
property_name,
location_name,
COALESCE(average_monthly_rent,0) AS average_monthly_rent
FROM average_month_rent

