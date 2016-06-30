

import boto3
from datetime import datetime

running_instances_metric_name = 'NumberRunningInstances'
orphan_eips_metric_name = 'NumberOrphanElasticIps'
metric_namespace = 'EC2'

def lambda_handler(event, context):
    ec2 = boto3.resource('ec2')
    cloudwatch = boto3.client('cloudwatch')

    timestamp = datetime.utcnow()
    num_instances = count_instances(ec2)
    num_eips = count_orphin_eip(ec2)
    publish_metrics(cloudwatch, timestamp, num_instances, num_eips)
    print "Observed %s instances running at %s" % (num_instances, timestamp)
    print "Observed %s orphaned elastic ips at %s" % (num_eips, timestamp)

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

# Counts the number of unattached elastic ip's
def count_orphin_eip(ec2):
    total_eips = 0
    for eip in ec2.vpc_addresses.all():
        if not eip.association:
            total_eips += 1
    return total_eips

def publish_metrics(cloudwatch, timestamp, num_instances, num_eips):
    cloudwatch.put_metric_data(
        Namespace=metric_namespace,
        MetricData=[
            {
                'MetricName': running_instances_metric_name,
                'Timestamp': timestamp,
                'Value': num_instances,
                'Unit': 'Count',
            },
            {
                'MetricName': orphan_eips_metric_name,
                'Timestamp': timestamp,
                'Value': num_eips,
                'Unit': 'Count',
            },
            ]
        )

if __name__ == '__main__':
    lambda_handler({}, {})
