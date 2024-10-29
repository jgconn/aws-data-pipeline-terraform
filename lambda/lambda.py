import logging
import json
import boto3
import os

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

s3 = boto3.client('s3')

def clean_data(raw_data):
    cleaned_data = []
    for record in raw_data:
        name = record.get('name', '').strip() 
        if name:
            cleaned_data.append({
                'id': record['id'],
                'name': name,
                'email': record['email'],
                'age': record['age']
            })
    return cleaned_data

def handler(event, context):
    try:
        LOGGER.info('SQS EVENT: %s', event)

        for sqs_rec in event['Records']:
            s3_event = json.loads(sqs_rec['body'])
            LOGGER.info('S3 EVENT: %s', s3_event)

            if 'Records' in s3_event:
                for s3_rec in s3_event['Records']:
                    bucket_name = s3_rec['s3']['bucket']['name']
                    object_key = s3_rec['s3']['object']['key']

                    LOGGER.info('Processing bucket: %s', bucket_name)
                    LOGGER.info('Processing object: %s', object_key)

                    target_bucket = os.environ['TARGET_BUCKET'] 

                    try:
                        # Get the raw data from the S3 object
                        response = s3.get_object(Bucket=bucket_name, Key=object_key)
                        raw_data = json.loads(response['Body'].read().decode('utf-8'))

                        cleaned_data = clean_data(raw_data)

                        cleaned_object_key = f'cleaned/{object_key}'

                        # Save cleaned data to the target bucket
                        s3.put_object(
                            Bucket=target_bucket,
                            Key=cleaned_object_key,
                            Body=json.dumps(cleaned_data)
                        )
                        
                        LOGGER.info('Saved cleaned object %s to bucket %s', cleaned_object_key, target_bucket)

                    except Exception as process_exception:
                        LOGGER.error('Failed to process object %s: %s', object_key, process_exception)

            else:
                LOGGER.warning('No records found in S3 event: %s', s3_event)

    except Exception as exception:
        LOGGER.error('Unhandled exception: %s', exception)
        raise
