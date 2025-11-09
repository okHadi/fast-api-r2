# fast-api-r2

Demo Fast API that connects with SQL and R2.

### Local setup

Requirements: Python 3.12

```bash
python3 -m venv venv
source venv/bin/activate # if on unix
pip install --upgrade -r requirements.txt
fastapi dev src/main.py
```

Or using Docker:

```bash
docker build -t fast-api-r2 .
docker run -d -p 8000:8000 fast-api-r2
```

### Docs:

1- We have the following folders:

- src/controllers: contains the business logic for handling requests and responses.
- src/routes: defines the API endpoints and maps them to controller functions.
- src/schemas: defines data models and validation schemas using Pydantic.
- src/utils : contains utility functions and helpers.
- main.py: the entry point of the application.
- database.py: handles database connections and operations.

2- While schema file is defined, it is not being used in the current implementation. The reason is because the POST endpoint only needs images, which are handled by UploadFile (i.e validation is done there). We can use the schema file for responses, but for simplicity we are not doing it.

3- Instead of using simple boto3, decided on using aioboto3 for async support.

4- Using API key for simple authentication.

5- All secrets are stored in .env file.

6- No retry logic implemented for R2, but we can do something like wait for 3 seconds (poll) and then retry.

### Testing

Using curl:

```bash
# Get thumbnails
curl -X GET http://localhost:8000/api/thumbnails/ -H "X-API-Key: my_secret_api_key" -v


# Upload thumbnails
curl -X POST http://localhost:8000/api/thumbnails/ -H "X-API-Key: my_secret_api_key" -F "files=@h.png" -F "files=@h2.png" -v
```
