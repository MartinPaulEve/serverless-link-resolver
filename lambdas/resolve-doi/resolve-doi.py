from pprint import pprint
from boto3.dynamodb.conditions import Key
import boto3
import json


def get_doi(doi, dynamodb=None):
    if not dynamodb:
        dynamodb = boto3.resource('dynamodb')

    table = dynamodb.Table('tf_doi_table')
    response = table.get_item(
        Key={
            'doi': doi,
        }
    )
    return response['Item']


def lambda_handler(event, context):
    response = {}
    response["statusCode"]=302
    doi = event['queryStringParameters']['doi']
    response["headers"]={'Location': get_doi(doi)['url']}
    data = {}
    response["body"]=json.dumps(data)
    pprint(response)
    return response
