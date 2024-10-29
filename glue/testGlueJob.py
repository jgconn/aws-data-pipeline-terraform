import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

# Get the arguments passed to the Glue job
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

# Create a Glue context
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Define the source and target paths
source_path = 's3://justin-test-infra-target-bucket/cleaned/'
target_path = 's3://justin-test-infra-target-bucket/parquet/'

# Read JSON files from the cleaned data folder
df = spark.read.json(source_path)

# Write the DataFrame to Parquet format
df.write.parquet(target_path, mode='overwrite')

# Commit the job
job.commit()
