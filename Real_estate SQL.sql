WITH unit_occupancy AS (
SELECT
u.property_id,
COUNT(DISTINCT u.id) AS total_units,
COUNT(DISTINCT CASE WHEN l.valid_lease = 1 THEN u.id END) AS occupied_units
FROM cleaned_units u
LEFT JOIN cleaned_leases l ON u.id = l.unit_id
GROUP BY u.property_id
)
SELECT
  p.cl AS property_id,
  p.name,
  (occupied_units * 100.0 / total_units) As occupancy_rate
  FROM unit_occupancy uo
  JOIN cleaned_property p ON uo.property_id = p.cl
  WHERE (occupied_units * 100.0 / total_units) < 80;
  
  WITH total_arrears AS (
  SELECT 
  l.id AS location_id,
  l.name AS location_name,
  u.id AS unit_id
  FROM cleaned_locations l
  LEFT JOIN cleaned_property p ON l.id = p.location_id
  LEFT JOIN cleaned_units u ON p.cl = u.property_id
  
  )
  SELECT
  ta.location_id,
  ta.location_name,
  COALESCE(SUM(arrears), 0) AS total_arears
  FROM total_arrears ta
  LEFT JOIN cleaned_leases s ON ta.unit_id = s.unit_id
  GROUP BY ta.location_id, ta.location_name;
  
  WITH collection_efficiency AS (
SELECT 
 p.cl AS property_id,
 p.name AS property_name,
 u.id AS unit_id,
 l.arrears,
 l.rent_per_month
FROM cleaned_property p
LEFT JOIN cleaned_units u ON u.property_id = p.cl
LEFT JOIN cleaned_leases l ON u.id = l.unit_id
WHERE l.valid_lease = 1
)
SELECT
ce.property_id,
ce.property_name,
ROUND((1-(SUM(arrears)/ NULLIF(SUM(rent_per_month), 0))) * 100, 2) AS collection_efficiency
FROM collection_efficiency ce
GROUP BY ce.property_id, ce.property_name
ORDER BY collection_efficiency DESC
LIMIT 3 ;

WITH quality_check AS (
SELECT
l.id AS lease_id,
end_date,
start_date,
rent_per_month,
t.id AS tenant_id,
t.name AS tenant_name,
p.cl AS property_id,
p.name AS property_name,
u.id AS unit_id,
u.name AS unit_name,
CASE WHEN rent_per_month < 0 THEN "NEGATIVE_RENT"
 WHEN end_date < start_date THEN "END_BEFORE_START" END AS flag_reason
FROM cleaned_leases l
LEFT JOIN cleaned_tenants t ON l.tenant_id = t.id
LEFT JOIN cleaned_units u ON l.unit_id = u.id
LEFT JOIN cleaned_property p ON p.cl = u.property_id
WHERE l.rent_per_month < 0 
OR(l.end_date <> '' AND l.end_date< l.start_date)
)
SELECT 
lease_id,
property_name,
unit_name,
tenant_name,
flag_reason
FROM quality_check qc
ORDER BY lease_id;

WITH multi_unit_tenants AS (
SELECT 
t.id AS tenant_id,
t.name AS tenant_name, 
COUNT(DISTINCT u.id) AS unit_count,
GROUP_CONCAT(DISTINCT p.name ORDER BY p.name SEPARATOR ',') AS property_spanned
FROM cleaned_leases l
LEFT JOIN cleaned_tenants t ON t.id = l.tenant_id
LEFT JOIN cleaned_units u ON u.id = l.unit_id
LEFT JOIN cleaned_property p ON p.cl = u.property_id
WHERE l.valid_lease = 1 
GROUP BY t.id, t.name
HAVING COUNT(DISTINCT u.id) > 1
)
SELECT 
tenant_id,
tenant_name,
unit_count,
property_spanned
FROM multi_unit_tenants
ORDER BY unit_count DESC, tenant_name;
  