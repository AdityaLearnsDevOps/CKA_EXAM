import boto3
import time

def lambda_handler(event, context):
    print("event: " , event)
    print("context: " , context)
    ec2_resource = boto3.resource('ec2')
    
    # Get instance ID
    inst_id = event['detail']['instance-id']

    print("inst_id: " , inst_id)
    # Get instance object
    inst_obj = ec2_resource.Instance(inst_id)


    
    # Get details of existing instance for image:
    root_device_name = inst_obj.root_device_name
    print('root_device_name', root_device_name)
    arch = inst_obj.architecture
    virt_type = inst_obj.virtualization_type
    ## Fetch the main name part of inst:
    for t in inst_obj.tags:
        if t['Key'] == 'Name':
            inst_name = t['Value']

    inst_name_main = inst_name[-7:]
    
    # Get volumes from instance:
    inst_vols = inst_obj.volumes.all()
    # fetch volume ID of root device :
    for vol in inst_vols:
        print("vol.attachments.Device: ", vol.attachments[0]['Device'])
        if (vol.attachments[0]['Device'] == root_device_name):
            vol_id = vol.id
            vol_size = vol.size
            vol_volume_type = vol.volume_type
            print("vol_id: ", vol_id)
            break
     
    # Create EBS snapshot of the volume:
    ## https://docs.aws.amazon.com/boto3/latest/reference/services/ec2/client/create_snapshot.html
    snapshot = ec2_resource.create_snapshot(
        VolumeId=vol_id,
        Description='Creating snapshot of root volume of instance '+inst_id,
        TagSpecifications=[
            {
                'ResourceType': 'snapshot', # APNAMBIA - required as per docs
                'Tags': [
                    {
                        'Key': 'Name',
                        'Value': 'cka_exam_clust_ami_'+inst_name_main,
                    },
                    {
                        'Key': 'InstanceArch',
                        'Value': arch
                    },
                    {
                        'Key': 'InstanceID',
                        'Value': inst_id
                    },
                    {
                        'Key': 'InstanceVirtType',
                        'Value': virt_type
                    },
                    {
                        'Key': 'InstanceRootDeviceName',
                        'Value': root_device_name
                    },
                    {
                        'Key': 'InstanceVolumeId',
                        'Value': vol_id
                    },
                    {
                        'Key': 'InstanceVolSize',
                        'Value': vol_size
                    },
                    {
                        'Key': 'InstanceVolType',
                        'Value': vol_volume_type
                    }
                ]
            },
        ],
        DryRun=False
    )

    