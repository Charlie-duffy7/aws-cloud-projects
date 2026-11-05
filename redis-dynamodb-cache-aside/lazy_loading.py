import boto3
import redis
import json
import time

# ---- DynamoDB setup ----
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
TABLE_NAME = 'UsersTable'

def create_table_if_not_exists():
    existing = [t.name for t in dynamodb.tables.all()]
    if TABLE_NAME not in existing:
        dynamodb.create_table(
            TableName=TABLE_NAME,
            KeySchema=[{'AttributeName': 'UserID', 'KeyType': 'HASH'}],
            AttributeDefinitions=[{'AttributeName': 'UserID', 'AttributeType': 'S'}],
            BillingMode='PAY_PER_REQUEST'
        )
        print(f"Table '{TABLE_NAME}' created.")
    else:
        print(f"Table '{TABLE_NAME}' already exists.")

table = dynamodb.Table(TABLE_NAME)

# ---- Redis setup ----
# decode_responses=True so Redis gives back strings instead of bytes
redis_client = redis.StrictRedis(host='localhost', port=6379, db=0, decode_responses=True)

# save a user to DynamoDB
def put_user(UserID, flavor):
    table.put_item(Item={'UserID': UserID, 'flavor': flavor})
    print(f"Stored in DynamoDB: UserID={UserID}, flavor={flavor}")

# the lazy loading part
def get_user_with_cache(UserID):
    cache_key = f"user:{UserID}"

    # check redis first
    cached = redis_client.get(cache_key)
    if cached:
        print(f"Cache HIT for {UserID}: {cached}")
        return cached

    # not in redis, so go to dynamo
    print(f"Cache MISS for {UserID}, querying DynamoDB...")
    response = table.get_item(Key={'UserID': UserID})
    item = response.get('Item')

    if item:
        # save it in redis for next time, expires after 60 seconds
        redis_client.set(cache_key, json.dumps(item), ex=60)
        print(f"Stored in Redis: {cache_key} = {item}")
        return item
    else:
        print(f"No item found for UserID: {UserID}")
        return None

# what you actually call, always goes through the cache
def get_user(UserID):
    return get_user_with_cache(UserID)


if __name__ == "__main__":
    create_table_if_not_exists()
    time.sleep(10)  # 2 seconds wasn't enough for a new table

    put_user("user_001", "chocolate")

    print("\n--- First call (should be cache MISS) ---")
    result = get_user("user_001")
    print(f"Result: {result}")

    print("\n--- Second call (should be cache HIT) ---")
    result = get_user("user_001")
    print(f"Result: {result}")
