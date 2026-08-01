import boto3

def setSourceIpAddr(event, context):
    print('DDNS Event: \n')
    print(event)
    print('DDNS Context: \n')
    print(context)  

    # 

    # Fetch and set the Source IP Address
    if (event['requestContext'] != '') :
        if (event['requestContext']['http'] != '') :
            srcIp = event['requestContext']['http']['sourceIp']

    sourceIp = f'{srcIp}'

    route53Client = boto3.client('route53')
    response = route53Client.change_resource_record_sets(
        HostedZoneId='Z0043380MDSRQY9ETFS6',
        ChangeBatch={
            'Comment':'Updating HostedZone Record of devops.studyinst.link',
            'Changes':[
                {
                    'Action':'UPSERT',
                    'ResourceRecordSet': {
                        'Name':'devops.studyinst.link',
                        'Type':'A',
                        # ADITYA : Don't need Region + SetIdentifier to pick a HostedZone Record - If provided, AWS considers this record to be a latency-based routing policy.
                        # ADITYA : For DDNS project, Simple routing policy is enough
                        #'Region':'ap-south-1',    
                        #'SetIdentifier' : 'DDNSREC1',
                        'TTL':60,
                        'ResourceRecords':[
                            {
                                'Value':sourceIp    
                            }
                        ]

                    }
                }
            ]
        }
    )