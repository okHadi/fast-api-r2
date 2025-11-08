# https://developers.cloudflare.com/r2/examples/aws/boto3/
import boto3
from .settings import settings

s3 = boto3.resource('s3', endpoint_url=settings.r2_endpoint_url,
                    aws_access_key_id=settings.r2_access_key_id, aws_secret_access_key=settings.r2_secret_access_key)
