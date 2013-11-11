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
private class TestSmartsheetImportCon {

	
	static testmethod void smartsheetTest(){
		
		List<Opportunity> newOpps = new List<Opportunity>();
        
        newOpps.add(new Opportunity(Name='Test1',StageName='Closed - Won',CloseDate=system.now().date().addDays(-2),Type='New Customer',Probability=50,Amount=35000));
        newOpps.add(new Opportunity(Name='Test2',StageName='Prospecting',CloseDate=system.now().date().addDays(-1),Type='New Customer',Probability=97,Amount=675000));
        newOpps.add(new Opportunity(Name='Test3',StageName='Closed - Won',CloseDate=system.now().date().addDays(5),Type='New Customer',Probability=20,Amount=210000));
        newOpps.add(new Opportunity(Name='Test4',StageName='Prospecting',CloseDate=system.now().date().addDays(10),Type='New Customer',Probability=35,Amount=120000));
        newOpps.add(new Opportunity(Name='Test5',StageName='Upgrade',CloseDate=system.now().date().addDays(-10),Type='Existing Customer',Probability=80,Amount=90000));
        
        insert newOpps;
        
        List<Opportunity> insertedO = [Select Id, Name from Opportunity];
        
        system.assertEquals(5, insertedO.size()); // Assert the inserted Opportunities
        
        Smartsheet_Config__c config = TestHelper.createTestConfig('testConfig');
		
		Test.startTest();
		
		HttpClient.testResponse = TestHelper.getSheetsResponse(true);
		
		SmartsheetImportCon testCon = new SmartsheetImportCon();
		
		testCon.objectName = 'Opportunity';
		testCon.getOFields();
		
		testCon.getAllSheets();
		
		testCon.getsheets();
	
		HttpClient.testResponse = TestHelper.getSheetWithRows(true, newOpps[0].id, newOpps[1].id);
		testCon.sContent = (Smartsheet.Sheet)JSON.deserialize(HttpClient.testResponse.getBody(), Smartsheet.Sheet.class);

		testCon.getSheetFields();
		
		system.assertEquals(6, testCon.mapData.size());
		
		testCon.getMergeOptions();
		
		for(SmartsheetImportCon.MapWrapper mw : testCon.mapData){
			
			if(mw.columnName == 'Opportunity ID') {
				mw.oFieldName = 'Id';
			}
			if(mw.columnName == 'Name') {
				mw.oFieldName = 'Name';
			}
			if(mw.columnName == 'Stage') {
				mw.oFieldName = 'StageName';
			}
			if(mw.columnName == 'Close Date') {
				mw.oFieldName = 'CloseDate';
			}
			if(mw.columnName == 'Opportunity Type') {
				mw.oFieldName = 'Type';
			}
			if(mw.columnName == 'Probability') {
				mw.oFieldName = 'Probability';
			}		
				
		}
		system.assertEquals(false, testCon.isConflictPresent);
		
		testCon.performImport();

		testCon.isConflictPresent = true;
		
		for(SmartsheetImportCon.MergeWrapper w : testCon.mergeSObjects){
			w.selected = 'Smartsheet';
		}
		

		testCon.performImport();

		List<Opportunity> updated = [Select Id, Type, StageName from Opportunity where StageName = 'Testing Passed'];
		
		system.assertEquals(2, updated.size());
		
		Test.stopTest();
	}
}