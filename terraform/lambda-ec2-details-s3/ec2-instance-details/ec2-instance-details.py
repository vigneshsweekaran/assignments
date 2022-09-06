import boto3

def lambda_handler(event, context):
    
    ec2_resource = boto3.resource('ec2')
    instances = [instance.state["Name"] for instance in ec2_resource.instances.all()]
    
    print('Running: ', instances.count('running'))