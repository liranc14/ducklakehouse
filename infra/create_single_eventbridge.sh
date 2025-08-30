aws events put-rule \
  --name run-dbt-first-team-model \
  --schedule-expression "cron(0 8 * * ? *)" \
  --state ENABLED



aws events put-targets \
  --rule run-dbt-first-team-model \
  --targets "[
    {
      \"Id\": \"1\",
      \"Arn\": \"arn:aws:ecs:us-east-1:822853810208:cluster/duck_cluster\",
      \"RoleArn\": \"arn:aws:iam::822853810208:role/ecsEventsRole\",
      \"EcsParameters\": {
        \"LaunchType\": \"FARGATE\",
        \"TaskDefinitionArn\": \"arn:aws:ecs:us-east-1:822853810208:task-definition/dbt_jobs:2\",
        \"NetworkConfiguration\": {
          \"awsvpcConfiguration\": {
            \"subnets\": [
              \"subnet-083ecd4bf0df82b0e\", 
              \"subnet-056aa95076a30359b\",
              \"subnet-06c1ee1d35379f02d\",
              \"subnet-0119f7f818d7a6c2d\",
              \"subnet-051e65bebc4207e05\",
              \"subnet-0021e003159aabc5d\"
            ],
            \"securityGroups\": [\"sg-0114ff8eed54bcc0c\"],
            \"assignPublicIp\": \"ENABLED\"
          }
        }
      },
      \"Input\": \"{\\\"overrides\\\":{\\\"containerOverrides\\\":[{\\\"name\\\":\\\"dbt_jobs\\\",\\\"command\\\":[\\\"run\\\",\\\"-s\\\",\\\"first_team_model\\\"],\\\"cpu\\\":4096,\\\"memory\\\":2048}]}}\" 
    }
  ]"




