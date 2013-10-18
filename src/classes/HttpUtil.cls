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

public with sharing class HttpUtil {

	public static HttpResponse testResponse; // use it for testing
	private static String GENERIC_ERR = 'Error doing callout - Smartsheet API';
	
	public static String sendSmartsheetReq(String method, String postBody, String endpoint){
		
		HttpRequest req = new HttpRequest();
		Http http		= new Http();
		
		req.setmethod(method);
		req.setHeader('Authorization','Bearer ' + OpportunityPipelineConstants.getAccessToken());
		req.setHeader('Content-Type','application/json');
		req.setEndpoint(endpoint);
		
		if(method == 'POST' || method == 'PUT')
			req.setBody(postBody);
		
		HttpResponse res = new HttpResponse();
		
		try {
			
			system.debug('------------------- HTTP Request --------------------------------- ');
			system.debug(req);
			system.debug(req.getBody());
			system.debug('------------------- END HTTP Request --------------------------------- ');
			
			if(!Test.isRunningTest())
				res = http.send(req);
			else		
				res = testResponse;
			
			system.debug('------------------- HTTP RESPONSE --------------------------------- ');
			system.debug(res.getBody());
			system.debug('------------------- END HTTP RESPONSE --------------------------------- ');	
				
			if(res.getStatusCode() > 300){
				String errMsg = parseError(res.getBody());
				throw new SmartsheetException(GENERIC_ERR + ' ' + errMsg);
			}
				
		}catch(CalloutException e){
			throw new SmartsheetException(GENERIC_ERR + ' ' + e.getMessage());
		}
		
		return res.getBody();
		
		
	}
	
	private static String parseError(String jsonString){
		
		JSONParser parser = JSON.createParser(jsonString);
		Boolean isErr = false;
		String result = '';
		String reason, message;
		
		while (parser.nextToken() != null) {
			if(parser.getCurrentToken() == JSONToken.START_OBJECT && !isErr){
				parser.nextToken();
				if(parser.getText() == 'err' || parser.getText() == 'errorCode'){ //if first element in the json string is 'error'
					isErr = true;					
				}
			}			
			else if ((parser.getCurrentToken() == JSONToken.FIELD_NAME && isErr)){ //if the response is truly an error
				String fieldName = parser.getText();
				parser.nextToken();
		    	if(fieldName == 'message'){
		   			message = parser.getText();
		   		}
			}
		}
		
		if(message != null)
			result = message;
		
		return result;	
		
		
	}
	
	/************     TEST Methods   ****************/
	
	static testmethod void testHttpUtil(){
		
		SmartsheetTestHelper.createConfigs(false);
		
		HttpUtil.testResponse = SmartsheetTestHelper.getSheetResponse(true);
		
		String endpoint = 'test//:testpoint';
		
		String response = HttpUtil.sendSmartsheetReq('GET', null, endpoint);
		
		HttpUtil.testResponse = SmartsheetTestHelper.errResponse();
		
		try {
		
			String errResponse = HttpUtil.sendSmartsheetReq('GET', null, endpoint);
		
		}catch(SmartsheetException e){
			
			system.assertEquals('Error doing callout - Smartsheet API Not Found',e.getMessage());
				
		}
	}


}