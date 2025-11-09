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

### Testing

Using curl:

```bash
# Get thumbnails
curl -X GET http://localhost:8000/api/thumbnails/ -H "X-API-Key: my_secret_api_key" -v


# Upload thumbnails
curl -X POST http://localhost:8000/api/thumbnails/ -H "X-API-Key: my_secret_api_key" -F "files=@h.png" -F "files=@h2.png" -v
```
