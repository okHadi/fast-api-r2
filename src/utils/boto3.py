# https://developers.cloudflare.com/r2/examples/aws/boto3/

# https://pypi.org/project/aioboto3/
import aioboto3
from .settings import settings


session = aioboto3.Session()


def get_s3_client():
    """
    Returns an async context manager for S3 client configured for R2.
    Usage: async with get_s3_client() as s3:
    """
    return session.client(
        "s3",
        endpoint_url=settings.r2_endpoint_url,
        aws_access_key_id=settings.r2_access_key_id,
        aws_secret_access_key=settings.r2_secret_access_key,
    )
