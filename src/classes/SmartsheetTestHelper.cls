/****************************************************************************
	Copyright 2013 Smartsheet, Inc.
	
	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at
	
	http://www.apache.org/licenses/LICENSE-2.0
	
	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and       
	limitations under the License.             
*****************************************************************************/
@isTest
public class SmartsheetTestHelper {

    public static void createConfigs(boolean setDefaultTemplate) {
      
        List<Smartsheet_IO__c> configs = new List<Smartsheet_IO__c>();
        
        configs.add(new Smartsheet_IO__c(AccessToken__c='api.smartsheet.com'));
             
        insert configs;
      
    }
   
    public static HttpResponse getTemplatesResponse(boolean isSuccess){
        
        if(!isSuccess)
            return errResponse();
        
        HttpResponse res = new HttpResponse();
        
        String json = '['+
        '    {'+
        '        \"id\": 123456,'+
        '        \"name\": \"Test Template\",'+
        '        \"accessLevel\": \"OWNER\",'+
        '        \"description\": \"Test Template\"'+
        '    }'+
        ']';
        
        res.setStatus('Accepted');
        res.setStatusCode(200);
        res.setBody(json);
        
        return res;
        
    }
    
    public static HttpResponse getAllSheets(boolean isSuccess){
        
        if(!isSuccess)
            return errResponse();
        
        HttpResponse res = new HttpResponse();
        
        String json = '['+
        '    {'+
        '        \"id\": 1111,'+
        '        \"name\": \"Test Sheet1\",'+
        '        \"accessLevel\": \"OWNER\",'+
        '        \"description\": \"Test Sheet1\"'+
        '    },'+
        '    {'+
        '        \"id\": 2222,'+
        '        \"name\": \"Test Sheet2\",'+
        '        \"accessLevel\": \"OWNER\",'+
        '        \"description\": \"Test Sheet2\"'+
        '    },'+
        '    {'+
        '        \"id\": 3333,'+
        '        \"name\": \"Test Sheet3\",'+
        '        \"accessLevel\": \"OWNER\",'+
        '        \"description\": \"Test Sheet3\"'+
        '    }'+
        ']';
        
        res.setStatus('Accepted');
        res.setStatusCode(200);
        res.setBody(json);
        
        return res;
        
    }
    
    public static HttpResponse getSheetWithRows(boolean isSuccess, String oppid1, String oppid2){
        
        if(!isSuccess)
            return errResponse();
        
        HttpResponse res = new HttpResponse();
            
        String json = '{\"id\":4337982300809092,\"name\":\"Opportunity Pipeline 2013-01-06 12:37:00\",\"columns\":[{\"id\":3506888949163908,\"index\":0,\"title\":\"Opportunity ID\",\"type\":\"TEXT_NUMBER\",\"primary\":true},{\"id\":8010488576534404,\"index\":1,\"title\":\"Name\",\"type\":\"TEXT_NUMBER\"},{\"id\":692139182057348,\"index\":2,\"title\":\"Stage\",\"type\":\"TEXT_NUMBER\"},{\"id\":5195738809427844,\"index\":3,\"title\":\"Close Date\",\"type\":\"DATE\"},{\"id\":2943938995742596,\"index\":4,\"title\":\"Probability\",\"type\":\"TEXT_NUMBER\"},{\"id\":7447538623113092,\"index\":5,\"title\":\"Opportunity Type\",\"type\":\"TEXT_NUMBER\"}],\"rows\":[{\"id\":6037973306238852,\"rowNumber\":1,\"cells\":[{\"type\":\"TEXT_NUMBER\",\"value\":\"'+ oppid1 +'\",\"columnId\":3506888949163908},{\"type\":\"TEXT_NUMBER\",\"value\":\"Edge SLA\",\"columnId\":8010488576534404},{\"type\":\"TEXT_NUMBER\",\"value\":\"Testing Passed\",\"columnId\":692139182057348},{\"type\":\"DATE\",\"value\":\"2010-10-24 00:00:00\",\"columnId\":5195738809427844},{\"type\":\"TEXT_NUMBER\",\"value\":100.0,\"columnId\":2943938995742596},{\"type\":\"TEXT_NUMBER\",\"value\":\"Existing Customer - Upgrade\",\"columnId\":7447538623113092}],\"createdAt\":\"2013-01-06T12:38:37-05:00\",\"modifiedAt\":\"2013-01-06T12:38:37-05:00\"},{\"id\":3786173492553604,\"rowNumber\":2,\"cells\":[{\"type\":\"TEXT_NUMBER\",\"value\":\"'+ oppid2 + '\",\"columnId\":3506888949163908},{\"type\":\"TEXT_NUMBER\",\"value\":\"Grand Hotels SLA\",\"columnId\":8010488576534404},{\"type\":\"TEXT_NUMBER\",\"value\":\"Testing Passed\",\"columnId\":692139182057348},{\"type\":\"DATE\",\"value\":\"2010-10-24 00:00:00\",\"columnId\":5195738809427844},{\"type\":\"TEXT_NUMBER\",\"value\":100.0,\"columnId\":2943938995742596},{\"type\":\"TEXT_NUMBER\",\"value\":\"Existing Customer - Upgrade\",\"columnId\":7447538623113092}],\"createdAt\":\"2013-01-06T12:38:37-05:00\",\"modifiedAt\":\"2013-01-06T12:38:37-05:00\"}],\"accessLevel\":\"OWNER\",\"version\":23,\"permalink\":\"https://smartsheet.com/b/home?lx=PsVJSEB8iplR09CaU9EO6A\",\"createdAt\":\"2013-01-06T12:37:00-05:00\",\"modifiedAt\":\"2013-01-06T12:40:09-05:00\"}';
        
        res.setStatus('Accepted');
        res.setStatusCode(200);
        res.setBody(json);
        
        return res;
        
        
    }
    
    public static HttpResponse getCreateSheetResponse(boolean isSuccess){
    
        if(!isSuccess)
            return errResponse();
        
        HttpResponse res = new HttpResponse();
        
    
        String json = '{'+
        '    \"resultCode\": 0,'+
        '    \"result\": {'+
        '        \"id\": 131250812938116,'+
        '        \"name\": \"Opportunity Pipeline 2013-05-19 22:03:19\",'+
        '        \"accessLevel\": \"OWNER\",'+
        '        \"permalink\": \"https://smartsheet.com/b/home?lx=ncrEgtyy80-uNXVfUEYVWA\"'+
        '    },'+
        '    \"message\": \"SUCCESS\"'+
        '}';
        
        res.setStatus('Accepted');
        res.setStatusCode(200);
        res.setBody(json);
        
        return res;
        
    }
    
    public static HttpResponse getNewSheetResponse(boolean isSuccess){
        if(!isSuccess)
            return errResponse();
            
        HttpResponse res = new HttpResponse();
            
        String json = '{'+
        '    \"resultCode\": 0,'+
        '    \"result\": {'+
        '        \"id\": 4634850440308612,'+
        '        \"name\": \"Opportunity Pipeline 2013-05-19 22:51:46\",'+
        '        \"columns\": ['+
        '            {'+
        '                \"id\": 6348031290304388,'+
        '                \"index\": 0,'+
        '                \"title\": \"Opportunity ID\",'+
        '                \"type\": \"TEXT_NUMBER\",'+
        '                \"primary\": true'+
        '            },'+
        '            {'+
        '                \"id\": 4096231476619140,'+
        '                \"index\": 1,'+
        '                \"title\": \"Name\",'+
        '                \"type\": \"TEXT_NUMBER\"'+
        '            },'+
        '            {'+
        '                \"id\": 8599831103989636,'+
        '                \"index\": 2,'+
        '                \"title\": \"Stage\",'+
        '                \"type\": \"PICKLIST\",'+
        '                \"options\": ['+
        '                    \"Prospecting\",'+
        '                    \"Qualification\",'+
        '                    \"Needs Analysis\",'+
        '                    \"Value Proposition\",'+
        '                    \"Id. Decision Makers\",'+
        '                    \"Perception Analysis\",'+
        '                    \"Proposal/Price Quote\",'+
        '                    \"Negotiation/Review\",'+
        '                    \"Closed Won\",'+
        '                    \"Closed Lost\",'+
        '                    \"Renewal\",'+
        '                    \"Upgrade\",'+
        '                    \"Downgrade\"'+
        '                ]'+
        '            },'+
        '            {'+
        '                \"id\": 437056779380612,'+
        '                \"index\": 3,'+
        '                \"title\": \"Opportunity Type\",'+
        '                \"type\": \"PICKLIST\",'+
        '                \"options\": ['+
        '                    \"Existing Customer - Upgrade\",'+
        '                    \"Existing Customer - Replacement\",'+
        '                    \"Existing Customer - Downgrade\",'+
        '                    \"New Customer\"'+
        '                ]'+
        '            },'+
        '            {'+
        '                \"id\": 4940656406751108,'+
        '                \"index\": 4,'+
        '                \"title\": \"Probability (%)\",'+
        '                \"type\": \"TEXT_NUMBER\"'+
        '            }'+
        '        ],'+
        '        \"accessLevel\": \"OWNER\",'+
        '        \"permalink\": \"https://smartsheet.com/b/home?lx=9MUjWK7KyAmWFHd18oYAxg\"'+
        '    },'+
        '    \"message\": \"SUCCESS\"'+
        '}';    
        
        res.setStatus('Accepted');
        res.setStatusCode(200);
        res.setBody(json);
        
        return res;
    }
    
    public static HttpResponse getSheetResponse(boolean isSuccess){
        if(!isSuccess)
            return errResponse();
        
        HttpResponse res = new HttpResponse();
            
        String json = '{\"accessLevel\": \"OWNER\",'+
        '    \"columns\": ['+
        '       {'+
        '            \"id\": 12345,'+
        '            \"index\": 0,'+
        '            \"primary\": true,'+
        '            \"title\": \"Opportunity ID\",'+
        '            \"type\": \"TEXT_NUMBER\"'+
        '       },'+ 
        '       {'+
        '            \"id\": 12345,'+
        '            \"index\": 0,'+
        '            \"primary\": true,'+
        '            \"title\": \"Stage\",'+
        '            \"type\": \"TEXT_NUMBER\"'+
        '        },'+
        '        {'+
        '            \"id\": 1111,'+
        '            \"index\": 1,'+
        '            \"options\": ['+
        '                \"new\",'+
        '                \"in progress\",'+
        '                \"completed\"'+
        '            ],'+
        '            \"title\": \"Close Date\",'+
        '            \"type\": \"DATE\"'+
        '        }'+
        '    ],'+
        '    \"createdAt\": \"2012-07-24T18:22:29-07:00\",'+
        '    \"id\": 4583173393803140,'+
        '    \"modifiedAt\": \"2012-07-24T18:30:52-07:00\",'+
        '    \"name\": \"sheet 1\",'+
        '    \"permalink\": \"https://smartsheet.com/home?lx=pWNSDH9itjBXxBzFmyf-5w\",'+
        '    \"rows\": []'+
        '}';
        
        res.setStatus('Accepted');
        res.setStatusCode(200);
        res.setBody(json);
        
        return res;
        
            
    }
    
    public static HttpResponse errResponse(){
        
        String json = '{'+
        '    \"errorCode\": 1006,'+
        '    \"message\": \"Not Found\"'+
        '}';
        
        HttpResponse res = new HttpResponse();
        res.setStatus('Error');
        res.setStatusCode(404);
        res.setBody(json);
        
        return res;
        
        
    }
    
    
}