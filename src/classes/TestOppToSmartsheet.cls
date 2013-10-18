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
	
    static testmethod void testSmartsheetWOTemplates(){
    	 List<Opportunity> newOpps = new List<Opportunity>();
        
        newOpps.add(new Opportunity(Name='Test1',StageName='Closed - Won',CloseDate=system.now().date().addDays(-2),Type='New Customer',Probability=50));
        newOpps.add(new Opportunity(Name='Test2',StageName='Prospecting',CloseDate=system.now().date().addDays(-1),Type='New Customer',Probability=97));
        newOpps.add(new Opportunity(Name='Test3',StageName='Closed - Won',CloseDate=system.now().date().addDays(5),Type='New Customer',Probability=20));
        newOpps.add(new Opportunity(Name='Test4',StageName='Prospecting',CloseDate=system.now().date().addDays(10),Type='New Customer',Probability=35));
        newOpps.add(new Opportunity(Name='Test5',StageName='Upgrade',CloseDate=system.now().date().addDays(-10),Type='Existing Customer',Probability=80));
        newOpps.add(new Opportunity(Name='Test6',StageName='Closed - Won',CloseDate=system.now().date().addDays(-20),Type='New Customer',Probability=40));
        newOpps.add(new Opportunity(Name='Test7',StageName='Qualification',CloseDate=system.now().date().addDays(30),Type='New Customer',Probability=45));
        newOpps.add(new Opportunity(Name='Test8',StageName='Upgrade',CloseDate=system.now().date().addDays(-4),Type='Existing Customer',Probability=50));
        newOpps.add(new Opportunity(Name='Test9',StageName='Closed - Won',CloseDate=system.now().date().addDays(-20),Type='New Customer',Probability=40));
        newOpps.add(new Opportunity(Name='Test10',StageName='Qualification',CloseDate=system.now().date().addDays(30),Type='New Customer',Probability=45));
       
        insert newOpps;
        
        List<Opportunity> insertedO = [Select Id, Name from Opportunity];
        
        /* Assert the inserted Opportunities */
        system.assertEquals(10,newOpps.size()); 
        
        SmartSheetTestHelper.createConfigs(false);
        
        
        // Tests start here 
        Test.startTest();
        
	        Apexpages.Standardsetcontroller setCon = new Apexpages.Standardsetcontroller(newOpps);
	        
	        HttpUtil.testResponse = SmartSheetTestHelper.getTemplatesResponse(false);
	        
	        OpportunityToSmartSheet testCon = new OpportunityToSmartsheet(setCon);
	        
	        testCon.getAllOptions(); // Get the import Export
	        testCon.getallProbabilities(); // get the probabilities
	        testCon.getallStages(); // get all Opportunity Stages
	        testCon.getOFields(); // get all Opportunity Fields
	 		testCon.selectedOption   = 'Export';
	        testCon.importExport();
//	      	testCon.showMapper();	      	
//	      	system.assertEquals(true,testCon.showMappings);
	      		
	      	testCon.addRow();
	      	testCon.removeRow();
//	      	testCon.hideMapper();  
//	        system.assertEquals(false,testCon.showMappings);
	      	
	        testCon.report();
	        system.assertEquals(10,testCon.oppRecords.size()); // Returns all the Opportunity Records as no filters are applied
	        
	        testCon.selectedStage='Upgrade';
	        testCon.selectedProb = '>40';
	        testCon.opp1.CloseDate = system.now().date().addMonths(-3);
	        testCon.opp2.CloseDate = system.now().date().addMonths(3);
	        testCon.report();    
	          
	        system.assertEquals(2,testCon.oppRecords.size()); // Returns filtered Opportunity Records as no filters are applied
	      
	      	HttpUtil.testResponse = SmartsheetTestHelper.getNewSheetResponse(true);
	      
	        testCon.sendToSmartsheet();
	        
        Test.stopTest();
    }
    
    /*-------------------- Test Class -------------------*/
	
	
	static testmethod void testConstants(){
		
		SmartsheetTestHelper.createConfigs(true);
		
		String accessToken = OpportunityPipelineConstants.getAccessToken();		
		system.assertNotEquals(null, accessToken);
		
		String url 		   = OpportunityPipelineConstants.APIDOMAIN;
		system.assertNotEquals(null, url);
	
		OpportunityPipelineConstants.Sheet s = new OpportunityPipelineConstants.Sheet();		
		s.accessLevel = 'OWNER';
		s.description = 'test';
		s.id  		  = 'test';
		s.name		  = 'testsheet';
		
		OpportunityPipelineConstants.Columns col = new OpportunityPipelineConstants.Columns();
		col.id = '1';
		col.index = 1;
		col.primary = true;
		col.title = 'test';
		col.type  = 'STRING';
		
		OpportunityPipelineConstants.Rows  row = new OpportunityPipelineConstants.Rows();
		row.columnId = '1';
		row.strict	 = false;
		row.value	 = '123';
		
		OpportunityPipelineConstants.RowData rData = new OpportunityPipelineConstants.RowData();
		rData.cells = new List<OpportunityPipelineConstants.Rows>{row};
		
		OpportunityPipelineConstants.SheetContent con = new OpportunityPipelineConstants.SheetContent();
		con.accessLevel = 'OWNER';
		con.columns = new List<OpportunityPipelineConstants.Columns>{col};
		con.createdAt = 'test';
		con.id = '1';
		con.modifiedAt = 'test';
		con.name = 'test';
		con.permalink = 'tet';
		con.version = '1';
		
		OpportunityPipelineConstants.Result sRes 		= new OpportunityPipelineConstants.Result();
		OpportunityPipelineConstants.RowWrapper sWrapper = new OpportunityPipelineConstants.RowWrapper();
		OpportunityPipelineConstants.SmartSheet sSheet	= new OpportunityPipelineConstants.SmartSheet();
		OpportunityPipelineConstants.ColumnsImp sCols    = new OpportunityPipelineConstants.ColumnsImp();
		OpportunityPipelineConstants.RowsImp sRows		= new OpportunityPipelineConstants.RowsImp();
		OpportunityPipelineConstants.SmartsheetImp sSm   = new OpportunityPipelineConstants.SmartsheetImp();
		OpportunityPipelineConstants.CellsImp sCells 	= new OpportunityPipelineConstants.CellsImp();
	}
}