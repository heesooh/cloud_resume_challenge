import json
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('cloud_resume_challenge_visitor_count')

def lambda_handler(event, context):
    response = table.update_item(
        Key = {'id', 'vistor_counter'},
        UpdateExpression = 'ADD #c :inc',
        ExpressionAttributeNames = {'#c': 'count'},
        ExpressionAttributeValues = {':inc': 1}
        ReturnValues = "UPDATED_NEW"
    )

    return {
        'statusCode': 200,
        'body': json.dumps(response['Attributes']['count'])
    }
