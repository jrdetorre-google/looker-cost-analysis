view: bq_logs {
  label: "BQ Logs"
  derived_table: {
    sql: (SELECT project_id, timestamp, insertId, logname, labels, billed_bytes, query_completion, statement_type FROM
            (SELECT resource.labels.project_id as project_id,
                    timestamp,
                    insertId,
                    logname,
                    protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobConfiguration.labels as labels,
                    protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.totalBilledBytes as billed_bytes,
                    protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.endTime as query_completion,
                    protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobConfiguration.query.statementType as statement_type,
                    ROW_NUMBER() OVER(PARTITION BY resource.labels. project_id,timestamp, insertId ORDER BY 1, 2, 3) rnm
             FROM `jrdetorre-bq-demo.looker_logs.cloudaudit_googleapis_com_data_access_*`)
          WHERE rnm=1) ;;
    partition_keys: ["timestamp"]
    interval_trigger: "12 hours"
  }

  dimension: pk {
    primary_key: yes
    hidden: yes
    type: string
    sql: CONCAT(${TABLE}.project_id, ${TABLE}.timestamp, ${TABLE}.insertId) ;;
  }

  dimension: project_id {
    type: string
    sql: ${TABLE}.project_id ;;
  }

  dimension: looker_user_id {
    hidden: yes
    type: number
    sql: CAST((SELECT value FROM UNNEST(${TABLE}.labels) as label WHERE label.key = 'looker-context-user_id') AS INT64) ;;
  }

  dimension: billed_bytes {
    hidden: yes # Use measure instead
    type: number
    sql: ${TABLE}.billed_bytes ;;
  }

  dimension_group: query_completion {
    type: time
    datatype: timestamp
    timeframes: [raw, date, year, month, month_name, week]
    sql: ${TABLE}.query_completion ;;
  }

  dimension: query_statement_type {
    type: string
    sql: ${TABLE}.statement_type ;;
  }

  dimension: estimated_on_demand_cost {
    hidden: yes # Use measure instead
    # Model creation costs more per GB than other statement types
    label: "Estimated On-Demand Cost"
    description: "Extrapolates from estimated billed bytes to cost in USD for on-demand pricing. Most statements are calculated at $5 USD / TiB, and BQML model creation is calculated at $250 USD / TiB"
    type: number
    value_format: "$0.000000000"
    sql: IF(${billed_bytes} IS NULL, 0.00,
                                     ${billed_bytes} / POW(2, 40)  *
                                      CASE
                                        WHEN ${query_statement_type} = 'CREATE_MODEL' THEN 250.00
                                        WHEN ${query_statement_type} IN ('DELETE','SELECT','CREATE_TABLE_AS_SELECT','INSERT','MERGE') THEN 5.00
                                        WHEN ${query_statement_type} IS NULL THEN 0.00
                                      END) ;;
  }

  measure: total_billed_bytes {
    type: sum
    sql: ${billed_bytes} ;;
  }

  measure: total_estimated_on_demand_cost {
    label: "Total Estimated On-Demand Cost"
    type: sum
    value_format: "$0.000000000"
    sql: ${estimated_on_demand_cost} ;;
    drill_fields: [project_id, looker_user_id, looker_users.user_name, looker_users.user_email, query_completion_date, estimated_on_demand_cost]
  }

}
