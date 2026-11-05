# Redis + DynamoDB Lazy Loading

Small project from my cloud class at USU (spring 2026). It's a Python script that uses Redis as a cache in front of DynamoDB. When you look up a user, it checks Redis first. If the user isn't there, it pulls them from DynamoDB and saves them in Redis for 60 seconds.

The functions:
- `put_user()` saves a user to DynamoDB
- `get_user_with_cache()` does the actual cache logic
- `get_user()` is what you call, and it always goes through the cache

When you run it, it adds a test user and looks it up twice. The first lookup is a cache miss and goes to DynamoDB. The second one is a hit and comes straight from Redis.

## Running it

You need Docker, Python, and AWS credentials set up with `aws configure`.

```bash
docker run -d -p 6379:6379 --name redis redis
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python lazy_loading.py
```

To see what got cached:

```bash
docker exec -it redis redis-cli get "user:user_001"
```

## What went wrong

The first run crashed with a `ResourceNotFoundException` because the DynamoDB table wasn't done being created yet. I bumped the wait from 2 seconds to 10.

I didn't have Redis installed on my Mac, so I just ran it in Docker.

## Next time

A fixed 10 second wait is kind of a hack. boto3 has `wait_until_exists()`, which waits until the table is actually ready, so I'd switch to that. I'd also fix the return type. Right now a cache hit returns a JSON string and a miss returns a dict.

## Credit

The starter code for connecting to DynamoDB and Redis came from my class repo (`czabriskie/redis-dynamo`). I combined it into one script and added the caching logic.

---

*AI note: I used Claude (an AI assistant) while building this to help with the code and debugging, and to help write this README.*
