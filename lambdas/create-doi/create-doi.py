from pprint import pprint
from boto3.dynamodb.conditions import Key
import boto3


def put_doi(doi, url, dynamodb=None):
    if not dynamodb:
        dynamodb = boto3.resource('dynamodb')

    table = dynamodb.Table('tf_doi_table')
    response = table.put_item(
        Item={
            'doi': doi,
            'url': url,
        }
    )
    return response


def lambda_handler(event, context):
    doi_resp = put_doi("10.1080/10436928.2020.1709713",
                       "https://www.tandfonline.com/doi/full/10.1080/10436928.2020.1709713")
    print("Put DOI succeeded:")
    pprint(doi_resp, sort_dicts=False)
    message = 'Done!'
    return {
        'message': message
    }


if __name__ == '__main__':
    doi_resp = put_doi("10.1080/10436928.2020.1709713",
                       "https://www.tandfonline.com/doi/full/10.1080/10436928.2020.1709713")
    print("Put DOI succeeded:")
    pprint(doi_resp, sort_dicts=False)
