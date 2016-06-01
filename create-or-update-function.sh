#!/bin/bash

set -e

REGION=${REGION:-us-east-1}

# aws iam get-user
# {
#     "User": {
#         "PasswordLastUsed": "2016-06-01T21:21:04Z", 
#         "CreateDate": "2011-07-16T23:53:31Z", 
#         "UserId": "123456", 
#         "Arn": "arn:aws:iam::123456:root"
#     }
# }
ACCOUNT_ID=$(aws iam get-user|python -c "import json as j,sys;o=j.load(sys.stdin);print o['User']['Arn'].split(':')[4]")

if ! aws lambda get-function --function-name count-ec2-instances &> /dev/null; then
    echo "Function does not exist, creating..."
    ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/CountEc2InstancesLambdaRole"
    aws lambda create-function \
	    --function-name count-ec2-instances \
	    --zip-file fileb://deployment-package.zip \
	    --handler main.lambda_handler \
	    --runtime python2.7 \
	    --memory-size 512 \
	    --timeout 15 \
	    --role "$ROLE_ARN"
else
    echo "Function already exists, updating..."
	aws lambda update-function-code --function-name count-ec2-instances --zip-file fileb://deployment-package.zip
fi



aws events put-rule \
    --name EveryFiveMinutes \
    --schedule-expression 'rate(5 minutes)'

aws events put-targets \
    --rule EveryFiveMinutes \
    --targets "{\"Id\" : \"1\", \"Arn\": \"arn:aws:lambda:$REGION:$ACCOUNT_ID:function:count-ec2-instances\"}"


if ! aws lambda get-policy --function-name count-ec2-instances 2> /dev/null | grep CountInstanceSchePerm > /dev/null; then
    echo "Setting policy so schedule event will trigger function"
    aws lambda add-permission \
        --function-name count-ec2-instances \
        --statement-id CountInstanceSchePerm \
        --action 'lambda:InvokeFunction' \
        --principal events.amazonaws.com \
        --source-arn "arn:aws:events:$REGION:$ACCOUNT_ID:rule/EveryFiveMinutes"
else
    echo "Events already have permission to trigger function."
fi


