aws iam put-user-policy \
  --user-name duck \
  --policy-name AllowPassEcsEventsRole \
  --policy-document file://pass-role-policy.json
