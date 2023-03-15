view: info_schema {
  derived_table: {
    sql:  SELECT
    creation_time as timestamp,
    project_id,
    user_email,
    job_type,
    statement_type,
    total_bytes_processed,
    total_bytes_billed,
    total_slot_ms,
    key,
    value
  FROM
    `jrdetorre-bq-demo.`.`region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
  CROSS JOIN
    UNNEST(labels)
      WHERE key='looker-context-user_id';;
#    partition_keys: ["timestamp"]
#    interval_trigger: "10 minutes"
    }

dimension: pk {
  primary_key: yes
  hidden: yes
  type: string
  sql: CONCAT(${TABLE}.project_id, ${TABLE}.timestamp) ;;
  }


  dimension: project_id {
    type: string
    sql: ${TABLE}.project_id ;;
  }

  dimension: looker_user_id {
    hidden: yes
    type: number
    sql: CAST(value) AS INT64) ;;
  }

  dimension: total_billed_bytes {
    hidden: yes # Use measure instead
    type: number
    sql: ${TABLE}.total_billed_bytes ;;
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
    sql: IF(${total_billed_bytes} IS NULL, 0.00,
                                     ${total_billed_bytes} / POW(2, 40)  *
                                      CASE
                                        WHEN ${query_statement_type} = 'CREATE_MODEL' THEN 250.00
                                        WHEN ${query_statement_type} IN ('DELETE','SELECT','CREATE_TABLE_AS_SELECT','INSERT','MERGE') THEN 5.00
                                        WHEN ${query_statement_type} IS NULL THEN 0.00
                                      END) ;;
  }


  measure: total_estimated_on_demand_cost {
    label: "Total Estimated On-Demand Cost"
    type: sum
    value_format: "$0.000000000"
    sql: ${estimated_on_demand_cost} ;;
#    drill_fields: [project_id, looker_user_id, looker_users.user_name, looker_users.user_email, query_completion_date, estimated_on_demand_cost]
  }


}
