view: looker_users {
  sql_table_name: `jrdetorre-bq-demo.looker_logs.users` ;;

  dimension: user_id {
    primary_key: yes
    type: number
    sql: ${TABLE}.User_ID ;;
  }

  dimension: user_name {
    type: string
    sql: ${TABLE}.Name ;;
  }

  dimension: user_email {
    type: string
    sql: ${TABLE}.User_Email ;;
  }

  measure: number_of_users {
    type: count
    drill_fields: [user_id, user_name, user_email]
  }

}
