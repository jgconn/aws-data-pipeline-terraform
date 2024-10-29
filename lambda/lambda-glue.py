import os
import boto3

glue_client = boto3.client('glue')

def handler(event, context):
    glue_job_name = os.environ['GLUE_JOB_NAME']
    bucket = os.environ['TARGET_BUCKET']
    input_prefix = os.environ['INPUT_PREFIX']
    output_prefix = os.environ['OUTPUT_PREFIX']
    
    try:
        response = glue_client.start_job_run(
            JobName=glue_job_name,
            Arguments={
                '--bucket': bucket,
                '--input-prefix': input_prefix,
                '--output-prefix': output_prefix
            }
        )
        return {
            'statusCode': 200,
            'body': f"Started Glue Job: {response['JobRunId']}"
        }
    except Exception as e:
        print(e)
        raise e