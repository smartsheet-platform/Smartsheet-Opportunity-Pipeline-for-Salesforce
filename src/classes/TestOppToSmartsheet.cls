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
private class TestOppToSmartsheet {
	
    static testmethod void testSmartsheet(){
    	 List<Opportunity> newOpps = new List<Opportunity>();
        
        newOpps.add(new Opportunity(Name='Test1',StageName='Closed - Won',CloseDate=system.now().date().addDays(-2),Type='New Customer',Probability=50,Amount=15000));
        newOpps.add(new Opportunity(Name='Test2',StageName='Prospecting',CloseDate=system.now().date().addDays(-1),Type='New Customer',Probability=97,Amount=125000));
        newOpps.add(new Opportunity(Name='Test3',StageName='Closed - Won',CloseDate=system.now().date().addDays(5),Type='New Customer',Probability=20,Amount=220000));
        newOpps.add(new Opportunity(Name='Test4',StageName='Prospecting',CloseDate=system.now().date().addDays(10),Type='New Customer',Probability=35,Amount=85000));
        newOpps.add(new Opportunity(Name='Test5',StageName='Upgrade',CloseDate=system.now().date().addDays(-10),Type='Existing Customer',Probability=80,Amount=15000));
        newOpps.add(new Opportunity(Name='Test6',StageName='Closed - Won',CloseDate=system.now().date().addDays(-20),Type='New Customer',Probability=40,Amount=270000));
        newOpps.add(new Opportunity(Name='Test7',StageName='Qualification',CloseDate=system.now().date().addDays(30),Type='New Customer',Probability=45,Amount=120000));
        newOpps.add(new Opportunity(Name='Test8',StageName='Upgrade',CloseDate=system.now().date().addDays(-4),Type='Existing Customer',Probability=50,Amount=250000));
        newOpps.add(new Opportunity(Name='Test9',StageName='Closed - Won',CloseDate=system.now().date().addDays(-20),Type='New Customer',Probability=40,Amount=75000));
        newOpps.add(new Opportunity(Name='Test10',StageName='Qualification',CloseDate=system.now().date().addDays(30),Type='New Customer',Probability=45,Amount=50000));
       
        insert newOpps;
        
        List<Opportunity> insertedO = [Select Id, Name from Opportunity];
        
        /* Assert the inserted Opportunities */
        system.assertEquals(10,newOpps.size()); 
        
        Smartsheet_Config__c config = TestHelper.createTestConfig('testConfig');

        
        // Tests start here 
        Test.startTest();
        
	        Apexpages.Standardsetcontroller setCon = new Apexpages.Standardsetcontroller(newOpps);
	        
	        OpportunityToSmartSheet testCon = new OpportunityToSmartsheet(setCon);
	        
	        testCon.getAllOptions(); // Get the import Export
	        testCon.getallProbabilities(); // get the probabilities
	        testCon.getallStages(); // get all Opportunity Stages
	        testCon.getOFields(); // get all Opportunity Fields
	 		testCon.selectedOption = 'Export';
	        testCon.importExport();

			testCon.authTypeSelect();
			testCon.oauthTarget();
			testCon.authenticate();
			
			testCon.toggleDeleteToken();
			testCon.deleteToken();
			testCon.sendToSmartsheet();
			
	      	testCon.addRow();
	      	testCon.removeRow();
	      	
	        testCon.report();
	        system.assertEquals(10, testCon.oppRecords.size()); // Returns all the Opportunity Records as no filters are applied
	        
	        testCon.selectedStage='Upgrade';
	        testCon.selectedProb = '>40';
	        testCon.opp1.CloseDate = system.now().date().addMonths(-3);
	        testCon.opp2.CloseDate = system.now().date().addMonths(3);
	        testCon.report();    
	          
	        system.assertEquals(2, testCon.oppRecords.size()); // Returns filtered Opportunity Records as no filters are applied
	      	
	        testCon.sendToSmartsheet();
	        
        Test.stopTest();
    }
    
    /*-------------------- Test Class -------------------*/
	
	
	static testmethod void testConstants(){
		
        Smartsheet_Config__c config = TestHelper.createTestConfig('testConfig');

		Smartsheet.Sheet s = new Smartsheet.Sheet();		
		s.accessLevel = 'OWNER';
		s.name		  = 'testsheet';
		
		Smartsheet.Column col = new Smartsheet.Column();
		col.id = 1;
		col.index = 1;
		col.primary = true;
		col.title = 'test';
		col.type  = 'STRING';
		
		List<Smartsheet.Column> columns = new List<Smartsheet.Column>();
		columns.add(col);
		
		Smartsheet.Cell cell = new Smartsheet.Cell();
		cell.columnId = 1;
		cell.strict	 = false;
		cell.value	 = '123';
		
		Smartsheet.Row row = new Smartsheet.Row();
		List<Smartsheet.Cell> cells = new List<Smartsheet.Cell>();
		cells.add(cell);
		
		row.cells = cells;
		
		List<Smartsheet.Row> rows = new List<Smartsheet.Row>();
		rows.add(row);
			
		s.columns = columns;
		s.rows = rows;
	}
}