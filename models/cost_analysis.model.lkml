connection: "jrdetorre_cost_analysis"

include: "/**/views/*.view"

explore: looker_users {
  join: bq_logs {
    type: left_outer
    relationship: one_to_many
    sql_on: ${looker_users.user_id} = ${bq_logs.looker_user_id} ;;
  }
}
