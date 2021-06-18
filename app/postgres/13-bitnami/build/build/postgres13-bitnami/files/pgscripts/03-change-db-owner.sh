#!/bin/bash
##############
PG_DB_USER=$1
PG_DB_NAME=$2
##############


PG_TYPES=" \
_acc_entry_type \
_account_living_count_type \
_account_living_count_without_sum_type \
_after_common_meters_formula_name \
_common_meter_formula_name \
_dependent_formula_name \
_dependent_formula_volume_type \
_dt_kt_enum \
_flat_meters_connection_type \
_gis_list_fields_type \
_individual_meter_formula_name \
_individual_volumes_meter_type \
_meter_model_type \
_meter_state \
_meter_value_source_enum \
_meter_values_type \
_model_appeal_qc_type \
_model_budget_archival_type_enum \
_model_document_type \
_model_payment_request_status_enum \
_model_repair_item_repair_type \
_model_repair_item_status \
_model_shutdown_type \
_operation_type \
_payment_splitting_stage_algo_type \
_payment_splitting_stage_purpose_type \
_peni_save_data \
_services_invoice_template_reference_group_by \
_work_calendar_type_enum \
_working_flat_meters_type \
_working_individual_meters_count_type \
acc_entry_type \
account_living_count_type \
account_living_count_without_sum_type \
after_common_meters_formula_name \
common_meter_formula_name \
dependent_formula_name \
dependent_formula_volume_type \
dt_kt_enum \
flat_meters_connection_type \
gis_list_fields_type \
individual_meter_formula_name \
individual_volumes_meter_type \
meter_model_type \
meter_state \
meter_value_source_enum \
meter_values_type \
model_budget_archival_type_enum \
model_document_type \
model_payment_request_status_enum \
model_repair_item_repair_type \
model_repair_item_status \
model_shutdown_type \
operation_type \
payment_splitting_stage_algo_type \
payment_splitting_stage_purpose_type \
peni_save_data \
services_invoice_template_reference_group_by \
work_calendar_type_enum \
working_flat_meters_type \
working_individual_meters_count_type \
after_common_meters_formula_name \
common_meter_formula_name \
dependent_formula_name \
flat_meters_connection_type \
meter_model_type \
meter_state \
meter_value_source_enum \
model_appeal_qc_type \
model_document_type \
model_payment_request_status_enum \
payment_splitting_stage_algo_type \
work_calendar_type_enum \
"


help_usage(){
	echo "USAGE: scriptname PG_DB_USER  PG_DB_NAME"
	echo "EXAMPLE:  /bin/bash /pgscripts/03-change-db-owner.sh \"user1\" \"test_db\""
}



check_variables() {
pattern=$'*( |\t)'
if [[ ${PG_DB_USER} = $pattern ]]; then
    echo "First parameter PG_DB_USER has no non-whitespace characters"
    exit 1
fi
if [[ ${PG_DB_NAME} = $pattern ]]; then
    echo "Third parameter PG_DB_NAME has no non-whitespace characters"
    exit 1
fi
}


rights_db() {
    echo "Изменяем владельца базы ${PG_DB_NAME} на  ${PG_DB_USER}"
for tbl in `psql    -qAt -c "select tablename from pg_tables where schemaname = 'public';" ${PG_DB_NAME}` \
           `psql    -qAt -c "select sequence_name from information_schema.sequences where sequence_schema = 'public';" ${PG_DB_NAME}` \
           `psql    -qAt -c "select table_name from information_schema.views where table_schema = 'public';" ${PG_DB_NAME}` ;
do
	  echo "ALTER TABLE $tbl in DATABASE ${PG_DB_NAME} TO USER ${PG_DB_USER}"
    psql   -c "alter table \"$tbl\" owner to \"${PG_DB_USER}\"" ${PG_DB_NAME} ;
done

}


rights_db_reports() {
    echo "Изменяем владельца базы ${PG_DB_NAME} на  ${PG_DB_USER}"
for tbl in `psql    -qAt -c "select tablename from pg_tables where schemaname = 'reports';" ${PG_DB_NAME}` \
           `psql    -qAt -c "select sequence_name from information_schema.sequences where sequence_schema = 'reports';" ${PG_DB_NAME}` \
           `psql    -qAt -c "select table_name from information_schema.views where table_schema = 'reports';" ${PG_DB_NAME}` ;
do
    echo "ALTER TABLE $tbl in DATABASE ${PG_DB_NAME} TO USER ${PG_DB_USER}"
    psql   -c "alter table \"$tbl\" owner to \"${PG_DB_USER}\"" ${PG_DB_NAME} ;
done
}

rights_func() {
  IFS=$'\n'
for fnc in `psql -qAt -c "SELECT  '\"' || p.proname||'\"' || '(' || pg_catalog.pg_get_function_identity_arguments(p.oid) || ')' FROM pg_catalog.pg_namespace n JOIN pg_catalog.pg_proc p ON p.pronamespace = n.oid WHERE n.nspname = 'public';" ${PG_DB_NAME}`
do
  echo "ALTER function $fnc in DATABASE ${PG_DB_NAME} TO USER ${PG_DB_USER}"
  psql -c "alter function $fnc owner to \"${PG_DB_USER}\"" ${PG_DB_NAME} ;
done
}

rights_func_reports() {

  psql -c "ALTER SCHEMA reports OWNER TO \"${PG_DB_USER}\"" ${PG_DB_NAME} ;
  psql -c "ALTER SCHEMA public OWNER TO \"${PG_DB_USER}\"" ${PG_DB_NAME} ;

}

rights_db_mat_view() {

for view_name_postgres in $(psql -qAt --dbname=${PG_DB_NAME} -c "SELECT oid::regclass::text FROM pg_class WHERE  relkind = 'm';")
do
    echo "ALTER mat view role ${view_name_postgres} in ${PG_DB_NAME} TO USER ${PG_DB_USER}"
    psql  -qAt --dbname=${PG_DB_NAME} -c  "ALTER MATERIALIZED VIEW  \"${view_name_postgres}\" OWNER TO \"${PG_DB_USER}\"";

done
}

rights_db_pg_type(){

  for PG_TYPE in $(echo ${PG_TYPES} | tr '\n' ' ')
  do
    echo "alter type ${PG_TYPE}  owner to ${PG_DB_USER} in ${PG_DB_NAME}"
    psql  -c "ALTER TYPE \"${PG_TYPE}\" OWNER TO \"${PG_DB_USER}\""  ${PG_DB_NAME} || (echo "ok")
  done
}

main() {

help_usage
check_variables
rights_func_reports
rights_db
#rights_db_reports
rights_func
#rights_db_mat_view
#rights_db_pg_type
}

main
