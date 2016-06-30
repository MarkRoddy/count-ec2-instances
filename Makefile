
help:
	@echo "make run: runs the program as it would as a lambda function"
	@echo "make deploy: create pre-reqs + deploy the lambda function"
	@echo "make libs: install local dependencies"
	@echo "make repl: drop into a repl with dependencies"

run:
	. .virtualenv/bin/activate && python main.py

deployment-package.zip: main.py libs
	zip deployment-package.zip main.py
	mv deployment-package.zip .virtualenv//lib/python2.7/site-packages/
	cd .virtualenv//lib/python2.7/site-packages/ && zip -r deployment-package.zip *
	mv .virtualenv//lib/python2.7/site-packages/deployment-package.zip  .

role:
	@ # Create the IAM role if it doesn't already exist
	if ! aws iam list-roles | grep CountEc2InstancesLambdaRole > /dev/null; then \
	  aws iam create-role --role-name CountEc2InstancesLambdaRole \
	    --assume-role-policy-document file://lambda-role-trust-policy.json; \
	fi
	@ # Create the role policy which has our authorization rules
	aws iam put-role-policy --role-name "CountEc2InstancesLambdaRole" \
	  --policy-name CountEc2InstancesPolicy --policy-document file://lambda-role-policy.json	

deploy:
	$(MAKE) role
	$(MAKE) deployment-package.zip
	./create-or-update-function.sh

libs:
	@if [ ! -d .virtualenv ]; then virtualenv .virtualenv; fi
	@. .virtualenv/bin/activate && pip install -r requirements.txt

repl:
	. .virtualenv/bin/activate && python
