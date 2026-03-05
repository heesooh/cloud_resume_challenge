import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('DYNAMODB_TABLE_NAME')
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    response = table.update_item(
        Key = {'id': 'vistor_counter'},
        UpdateExpression = 'ADD #c :inc',
        ExpressionAttributeNames = {'#c': 'count'},
        ExpressionAttributeValues = {':inc': 1},
        ReturnValues = "UPDATED_NEW"
    )

    # 'boto3' converts DynamoDB numbers into 'Decimal' type, 
    # thus convert to 'int' type before return
    updated_count = int(response['Attributes']['count']) 

    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'count': updated_count
        })
    }
