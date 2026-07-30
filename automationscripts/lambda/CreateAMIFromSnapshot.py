import json
import boto3

def lambda_handler(event, context):
    
    # Get the snapshot ID once EventBridge triggers post snapshot completion
    snapshot_id = event['detail']['snapshot-id']

    # Get the instance details to prepare a Name for AMI (As per given standard naming convention)

    ec2_resource = boto3.resource('ec2', region_name='ap-south-1')
    snapshot_resource = ec2_resource.Snapshot(snapshot_id)

    vol_id = snapshot_resource.volume_id
    vol_size = snapshot_resource.volume_size
    
    snap_tags = snapshot_resource.tags
    if (snap_tags is None): 
        raise Exception("Tags not found on the snapshot")
        
    for snap_tag in snap_tags:
        if snap_tag['Key'] == 'Name':
            inst_name_main = snap_tag['Value']
        if snap_tag['Key'] == 'InstanceID':
            clust_mast_inst_id = snap_tag['Value']
        if snap_tag['Key'] == 'InstanceVirtType':
            virt_type = snap_tag['Value']
        if snap_tag['Key'] == 'InstanceRootDeviceName':
            root_device_name = snap_tag['Value']
        if snap_tag['Key'] == 'InstanceArch':
            arch = snap_tag['Value']
        if snap_tag['Key'] == 'InstanceVolType':
            vol_volume_type = snap_tag['Value']

    print(f"Snapshot has fetched below details: \nInstance name: {inst_name_main}, \nInstanceID : {clust_mast_inst_id} , \nInstanceRootDeviceName : {root_device_name}")

    # Used the AMI register code to trigger AMI creation. (This is asynchronous)
    # Create AMI from the snapshot:
    ## https://docs.aws.amazon.com/boto3/latest/reference/services/ec2/client/register_image.html  
    ami_resp = ec2_resource.register_image(
        Name=inst_name_main,
        Description=f"Created from snapshot {snapshot_id} for instance {inst_name_main}",
        Architecture=arch,
        VirtualizationType=virt_type,
        RootDeviceName=root_device_name,
        BlockDeviceMappings=[
            {
                'DeviceName': root_device_name,
                'Ebs': {
                    'SnapshotId': snapshot_id,
                    'VolumeSize': vol_size,
                    'VolumeType': vol_volume_type,
                    'DeleteOnTermination': True
                }
            },
        ],
        DryRun=False
    )
    
    print(f"AMI creation now started. AMI ID: {ami_resp.image_id} ")