#!/bin/sh

POSTGRES_DATABASE="$1"

function help_usage(){
	echo "USAGE: scriptname PG_DBNAME"
	echo "EXAMPLE:  /bin/bash 07-refresh-mat-view.sh\"test_db\""
}

if [ "${POSTGRES_DATABASE}" == "" ];then
	echo "Arg POSTGRES_DATABASE is empty"
	exit
fi



view_list_postgres="view_accounting_entry_account_invoice_date \
view_accounting_entry_account_recalculation_date \
view_accounting_entry_account_restruct_date \
view_accounting_entry_account_peni \
view_accounting_entry_account_peni_date \
view_accounting_entry_account_peni_payment_date \
view_accounting_entry_company_debt_date \
view_accounting_entry_company_charge_date \
view_accounting_entry_account_payment_date"



for view_name_postgres in ${view_list_postgres}
do
echo "Refresh ${view_name_postgres} in ${POSTGRES_DATABASE}"
#psql -c "REFRESH MATERIALIZED VIEW \"${view_name_postgres}\"" ${PG_DB_NAME};
psql  -qAt -c   "REFRESH MATERIALIZED VIEW \"${view_name_postgres}\";" "${POSTGRES_DATABASE}" 
echo "Refresh ${view_name_postgres} in ${POSTGRES_DATABASE} done"
done
