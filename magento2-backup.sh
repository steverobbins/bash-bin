#!/bin/bash

createDbDump() {
    # Set path of env.php
    LOCALENVPATH=${MAGENTOROOT}app/etc/env.php

    # Get mysql credentials from local.xml
    getLocalValue() {
        PARAMVALUE=`grep $PARAMNAME $LOCALENVPATH | head -n 1 | awk '{print $3}'`
        PARAMVALUE="${PARAMVALUE:1:-2}"
    }

    # Connection parameters
    DBHOST=
    DBUSER=
    DBNAME=
    DBPASSWORD=
    TBLPRF=

    # Include DB logs option
    SKIPLOGS=1

    # Ignored table names
    IGNOREDTABLES="
    sales_bestsellers_aggregated_daily
    sales_bestsellers_aggregated_monthly
    sales_bestsellers_aggregated_yearly
    sales_creditmemo
    sales_creditmemo_comment
    sales_creditmemo_grid
    sales_creditmemo_item
    sales_invoice
    sales_invoice_comment
    sales_invoice_grid
    sales_invoice_item
    sales_invoiced_aggregated
    sales_invoiced_aggregated_order
    sales_order
    sales_order_address
    sales_order_aggregated_created
    sales_order_aggregated_updated
    sales_order_grid
    sales_order_item
    sales_order_payment
    sales_order_status
    sales_order_status_history
    sales_order_status_label
    sales_order_status_state
    sales_order_tax
    sales_order_tax_item
    sales_payment_transaction
    sales_refunded_aggregated
    sales_refunded_aggregated_order
    sales_sequence_meta
    sales_sequence_profile
    sales_shipment
    sales_shipment_comment
    sales_shipment_grid
    sales_shipment_item
    sales_shipment_track
    sales_shipping_aggregated
    sales_shipping_aggregated_order
    session"

    # Sanitize data
    SANITIZE=

    # Sanitazed tables
    SANITIZEDTABLES="
    customer_entity
    customer_entity_varchar
    customer_address_entity
    customer_address_entity_varchar"

    # Get DB HOST from local.xml
    if [ -z "$DBHOST" ]; then
        PARAMNAME=host
        getLocalValue
        DBHOST=$PARAMVALUE
    fi

    # Get DB USER from local.xml
    if [ -z "$DBUSER" ]; then
        PARAMNAME=username
        getLocalValue
        DBUSER=$PARAMVALUE
    fi

    # Get DB PASSWORD from local.xml
    if [ -z "$DBPASSWORD" ]; then
        PARAMNAME=password
        getLocalValue
        DBPASSWORD=${PARAMVALUE//\"/\\\"}
    fi

    # Get DB NAME from local.xml
    if [ -z "$DBNAME" ]; then
        PARAMNAME=dbname
        getLocalValue
        DBNAME=$PARAMVALUE
    fi

    # Get DB TABLE PREFIX from local.xml
    if [ -z "$TBLPRF" ]; then
        PARAMNAME=table_prefix
        getLocalValue
        TBLPRF=$PARAMVALUE
    fi

    # Check DB credentials for existsing
    if [ -z "$DBHOST" -o -z "$DBUSER" -o -z "$DBNAME" ]; then
        echo "Skip DB dumping due lack of parameters host=$DBHOST; username=$DBUSER; dbname=$DBNAME;";
        exit 0
    fi

    # Set connection params
    if [ -n "$DBPASSWORD" ]; then
        CONNECTIONPARAMS=" -u$DBUSER -h$DBHOST -p\"$DBPASSWORD\" $DBNAME --force --triggers --single-transaction --opt --skip-lock-tables"
    else
        CONNECTIONPARAMS=" -u$DBUSER -h$DBHOST $DBNAME --force --triggers --single-transaction --opt --skip-lock-tables"
    fi

    # Create DB dump
    IGN_SCH=
    IGN_IGN=
    SAN_CMD=

    if [ -n "$SANITIZE" ] ; then

        for TABLENAME in $SANITIZEDTABLES; do
            SAN_CMD="$SAN_CMD $TBLPRF$TABLENAME"
            IGN_IGN="$IGN_IGN --ignore-table='$DBNAME'.'$TBLPRF$TABLENAME'"
        done
        PHP_CODE='
        while ($line=fgets(STDIN)) {
            if (preg_match("/(^INSERT INTO\s+\S+\s+VALUES\s+)\((.*)\);$/",$line,$matches)) {
                $row = str_getcsv($matches[2],",","\x27");
                foreach($row as $key=>$field) {
                    if ($field == "NULL") {
                        continue;
                    } elseif ( preg_match("/[A-Z]/i", $field)) {
                        $field = md5($field . rand());
                    }
                    $row[$key] = "\x27" . $field . "\x27";
                }
                echo $matches[1] . "(" . implode(",", $row) . ");\n";
                continue;
            }
            echo $line;
        }'
        SAN_CMD="nice -n 15 mysqldump $CONNECTIONPARAMS --skip-extended-insert $SAN_CMD | php -r '$PHP_CODE' ;"
    fi

    if [ -n "$SKIPLOGS" ] ; then
        for TABLENAME in $IGNOREDTABLES; do
            IGN_SCH="$IGN_SCH $TBLPRF$TABLENAME"
            IGN_IGN="$IGN_IGN --ignore-table='$DBNAME'.'$TBLPRF$TABLENAME'"
        done
        IGN_SCH="nice -n 15 mysqldump --no-data $CONNECTIONPARAMS $IGN_SCH ;"
    fi

    IGN_IGN="nice -n 15 mysqldump $CONNECTIONPARAMS $IGN_IGN"

    DBDUMPCMD="( $SAN_CMD $IGN_SCH $IGN_IGN) | sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' | gzip > $DBFILENAME"

    echo ${DBDUMPCMD//"p\"$DBPASSWORD\""/p[******]}

    eval "$DBDUMPCMD"
}

################################################################################
# CODE
################################################################################

# Selftest
#checkTools

# Magento folder
MAGENTOROOT=./

# Output path
OUTPUTPATH=$MAGENTOROOT

# Input parameters
MODE=
NAME=

OPTS=`getopt -o m:n:o: -l mode:,name:,outputpath: -- "$@"`

if [ $? != 0 ]
then
    exit 1
fi

eval set -- "$OPTS"

while true ; do
    case "$1" in
        -m|--mode) MODE=$2; shift 2;;
        -n|--name) NAME=$2; shift 2;;
        -o|--outputpath) OUTPUTPATH=$2; shift 2;;
        --) shift; break;;
    esac
done

if [ -n "$NAME" ]; then
    DBFILENAME="$OUTPUTPATH$NAME.sql.gz"
else
    # Get random file name - some secret link for downloading from magento instance :)
    MD5=`echo \`date\` $RANDOM | md5sum | cut -d ' ' -f 1`
    DATETIME=`date -u +"%Y%m%d%H%M"`
    DBFILENAME="$OUTPUTPATH$MD5.$DATETIME.sql.gz"
fi

createDbDump

exit 0
