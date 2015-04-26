-- REQUIRES THREE ARGUMENTS:
-- $1 must be empty string, or comma-delimited string, or array of string as schema names to INCLUDE. 
select tc.table_schema as schema, tc.table_name as name, kc.column_name as pk
from 
    information_schema.table_constraints tc
    join information_schema.key_column_usage kc 
        on kc.table_name = tc.table_name and
           kc.constraint_schema = tc.table_schema and
           kc.constraint_name = tc.constraint_name 
where 
    tc.constraint_type = 'PRIMARY KEY'
    and 
    ((case -- allow specific schemas (none or '' assumes all):
      when $1 ='' then 1=1 
      else tc.table_schema = any(string_to_array(replace($1, ' ', ''), ',')) end)
    and
    (case -- Filter using LIKE by fully-qualified name (no schema assumes public):
      when $2 = '' then 1=1 
      else replace((tc.table_schema || '.'|| tc.table_name), 'public.', '') not like all(string_to_array(replace($2, ' ', ''), ',')) end))
    and
    (case -- whitelist specific tables, with fully-qualified name (no schema assumes public). 
      when $3 = '' then 1=1
      -- Below can use '%' as wildcard. Change 'like' to '=' to require exact names: 
      else replace((tc.table_schema || '.'|| tc.table_name), 'public.', '') = any(string_to_array(replace($3, ' ', ''), ',')) end)
order by tc.table_schema,
         tc.table_name,
         kc.position_in_unique_constraint;
