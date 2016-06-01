

import boto3
from datetime import datetime

metric_name = 'NumberRunningInstances'
metric_namespace = 'EC2'

def lambda_handler(event, context):
    ec2 = boto3.resource('ec2')
    cloudwatch = boto3.client('cloudwatch')

    timestamp = datetime.utcnow()
    num_instances = count_instances(ec2)
    publish_num_instances(cloudwatch, num_instances, timestamp)
    print "Observed %s instances running at %s" % (num_instances, timestamp)

def count_instances(ec2):
    total_instances = 0
    instances = ec2.instances.filter(          Filters=[
              {
                  'Name': 'instance-state-name',
                  'Values': [
                      'running',
                  ]
              },
        ])
    for _ in instances:
        total_instances += 1
    return total_instances

def publish_num_instances(cloudwatch, num_instances, timestamp):
    cloudwatch.put_metric_data(
        Namespace=metric_namespace,
        MetricData=[
            {
                'MetricName': metric_name,
                'Timestamp': timestamp,
                'Value': num_instances,
                'Unit': 'Count',
            }
            ]
        )

if __name__ == '__main__':
    lambda_handler({}, {})
