/***************************************************************************
 Name: SmartsheetImportCon 
 Created Date: 01/06/2013
 VisualForce Component: SmartsheetImport
 Description: Controller Class for SmartsheetImport Component
 Operations: Does the following to integrate with Smartsheet REST API
 
 1. get /sheets
 2. get the sheet /sheet/{sheetid}
 
 Imports the data from the Sheets to the respective Object record/s. Provides 
 ability to user to resolve Merge Conflicts. Merge Conflicts are handled, 
 using the following logic - 
 
 IF 
 	the SObject Record's LastModifiedDate is greater than Smartsheet Row's 
 	CreatedDate 
 THEN 
 	include that record as Conflict Record for User's input.
 ELSE
 	update the record
----- 	
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
******************************************************************************/
public with sharing class SmartsheetImportCon {
	
	private List<Smartsheet.Sheet> sheets;
	private Map<String, String> columnIdNameMap;
	private Map<String, String> objFields;
	private Map<String, Schema.DisplayType> fieldTypeMap;
	private Map<String, Smartsheet.Row> idRowMap;
	private List<SObject> sobjectRecs;
	private String oauthState;
    private SmartsheetApi api;  
	
	/* Public variables */
	public List<MapWrapper> mapData 		{get;set;}	
	public String  sheetId					{get;set;}
	public String objectName				{get;set;}
	public boolean isConflictPresent		{get;set;}
	public List<MergeWrapper> mergeSObjects {get;set;}
	public Smartsheet.Sheet sContent		{get;set;}
	
	
	/* Constructor */
	public SmartsheetImportCon(){
		
		sheets  = new List<Smartsheet.Sheet>();
		objFields = new Map<String, String>();
		fieldTypeMap = new Map<String, Schema.DisplayType>();
		mapData = new List<MapWrapper>();
		sobjectRecs = new List<SObject>();
		isConflictPresent = false;
		api = new SmartsheetApi();
		getAllSheets();
			
	}
	
	/* Gets all available Sheets from the Smartsheet. */
	public void getAllSheets(){
		
		try {
			/* get sheets */
			if(Test.isRunningTest()){
				HttpClient.testResponse = TestHelper.getSheetsResponse(true);
                List<Smartsheet.Sheet> sheets = (List<Smartsheet.Sheet>)JSON.deserialize(HttpClient.testResponse.getBody(), List<Smartsheet.Sheet>.class);
			} else {
				sheets = api.getSheets();
			}
			
			if(sheets.size() == 0) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 
					'No Sheets found - Create one in Smartsheet Site and Come back '));
			}
		}catch(SmartsheetException e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 
				'Error getting sheets from Smartsheet ' + e.getMessage()));
		}
	}
	
	/* Build a SelectOption List for all available Sheets. */
	public List<SelectOption> getsheets(){
		
		List<SelectOption> options = new List<SelectOption>();
		
		options.add(new SelectOption('', '-- Select from Available Sheets --'));
	
		
		for(Smartsheet.Sheet s : sheets){
			options.add(new SelectOption(String.valueOf(s.id), s.name));
		}
		
		return options;
	}
	
	/* Get the fields/columns for the selected Sheet. Used for mapping */
	public void getSheetFields(){
		
		mapData = new List<MapWrapper>();
		columnIdNameMap = new Map<String,String>();
		
		/* 
			sheetId is null if a sheet is selected in the import sheetSelection and then the selector is set back to 'Select a Sheet'.
			When this happens the API does not need to be called, only the page needs to be reset.
		*/
		if(sheetId != null || Test.isRunningTest()){
	
			try {
				if(!Test.isRunningTest()){
					sContent = api.getSheet(Long.valueOf(sheetId));
				}

				if(sContent != null && sContent.columns != null){ 
					for(Integer i=0; i < sContent.columns.size(); i++) {
						columnIdNameMap.put(String.valueOf(sContent.columns[i].id), sContent.columns[i].title);
						mapData.add(new MapWrapper(String.valueOf(sContent.columns[i].id), sContent.columns[i].title));
					}
					
					fieldsDescribe();
					autoMatch();
				}
			}catch(JSONException e){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 
					'Unable to Parse ' + e.getMessage()));
			}
		}
	}
	
	/* Get the available fields for the Selected Object */
	public List<SelectOption> getOFields(){
		
		List<SelectOption> options = new List<SelectOption>();
		
		options.add(new SelectOption('','-- Select Field --'));
		
		for(String s : objFields.keySet()){
			options.add(new SelectOption(objFields.get(s),s));
		}
		
		return options;
		
	}
	
	/* Get the Merge Options to use, either Salesforce or SmartSheet */
	public List<SelectOption> getMergeOptions(){
		
		List<SelectOption> options = new List<SelectOption>();
		
		options.add(new SelectOption('Salesforce', 'Salesforce'));
		options.add(new SelectOption('Smartsheet', 'Smartsheet'));
		
		return options;
		
	}
	
	/* Method that does the Field Describes */
	private void fieldsDescribe(){
		
		Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
		
		for(Schema.SObjectField f : fieldMap.values()){
			objFields.put(f.getDescribe().getLabel(),f.getDescribe().getName());
			fieldTypeMap.put(f.getDescribe().getName(),f.getDescribe().getType());
		}
		
	}
	
	/* Perform the AutoMatch for the Columns with SObject Fields */
	private void autoMatch(){
		for(MapWrapper ow : mapData){
			if(objFields.get(ow.columnName) != null){
				ow.oFieldName = objFields.get(ow.columnName); 
			}
		}
	}
	
	/*
		Main method that performs the Import from Smartsheet and Updates the Salesforce records.
	*/
	public void performImport(){
		
		Map<String, String> colIdName = new Map<String, String>();
		idRowMap = new Map<String, Smartsheet.Row>();
		
		/* If Conflict is Present and is resolved. */
		if(isConflictPresent){
			
			for(MergeWrapper mw : mergeSObjects){
				if(mw.selected == 'Salesforce'){
					sobjectRecs.add(mw.salesforceRec);
				}else{
					sobjectRecs.add(mw.smartsheetRec);	
				}
			}
			
			isConflictPresent = false;
			
		}else {
			/* Build the SObject Records */
			for(MapWrapper ow : mapData){
				colIdName.put(ow.columnId, ow.oFieldName);	
			}
			
			for(Smartsheet.Row row : sContent.rows){
				SObject thisObj;
				
				for(Smartsheet.Cell c : row.cells){
                    try{
                    	/* Adding the Object ID cell value */
                        if(colIdName.get(String.valueOf(c.columnId)) != null && colIdName.get(String.valueOf(c.columnId)) == 'Id'){
                            thisObj = Schema.getGlobalDescribe().get(objectName).newSObject(c.value);
                            idRowMap.put(c.value, row);	
                        }
                    }catch(NullPointerException e){
                        /* there isn't a column mapped to Object ID */
						System.debug('One Smartsheet column needs to be mapped to the ' + objectName + ' ID column.');                        
                    	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 
                    		'One Smartsheet column needs to be mapped to the ' + objectName + ' ID column.'));
                    	return;
                    }catch(StringException e){
						System.debug(e.getMessage() + '. The value of the Smartsheet column mapped to the ' + objectName + ' ID column is not a valid salesforce ID. ie: 006D000000CpOSy');                        
                        /* column mapped to OpportunityId contains invalid data */
                    	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 
                    		e.getMessage() + '. The value of the Smartsheet column mapped to the ' + objectName + ' ID column is not a valid salesforce ID. ie: 006D000000CpOSy'));
                    	return;                        
                    }
				}
				
				/* Adding other cell values that aren't Object ID */
				for(Smartsheet.Cell c : row.cells){
                    try{
                        if(colIdName.get(String.valueOf(c.columnId)) != null && colIdName.get(String.valueOf(c.columnId)) != 'Id'){
                            thisObj.put(colIdName.get(String.valueOf(c.columnId)), convertStringToObject(colIdName.get(String.valueOf(c.columnId)), c.value));  
                        }
                    }catch(NullPointerException e){
						System.debug('There was an issue with the value of ' + colIdName.get(String.valueOf(c.columnId)));                        
                         /* there was an issue adding a cell value, other than Object ID */
                    	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 
                    		'There was an issue with the value of ' + colIdName.get(String.valueOf(c.columnId))));
                    	return;                        
                    }
                }
                /* Add Records for Update */
				sobjectRecs.add(thisObj);
			}
			
			/* Compare the Records, with Salesforce Records. */
			compareRecords(sobjectRecs);
		}
		
		try {		
			if(!isConflictPresent)
				update sobjectRecs;
			else
				return;	
		}catch(DMLException e){		
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 
				'Error updating records ' + e.getMessage()));
			return;
		}
		
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 
			'Successfully Imported ' + sobjectRecs.size() +  ' Records'));
	}
	
	/*
		Method that does the Compare. Builds the dynamic SOQL and queries the Salesforce Database to retrieve Records.
	*/
	public void compareRecords(List<SObject> sobjRecs){
		
		Map<String, SObject> sobjMap = new Map<String, SObject>();
		Map<String, SObject> sfMap = new Map<String, SObject>();
		mergeSObjects = new List<MergeWrapper>();
		Set<ID> sobjids = new Set<Id>();
		
		for(SObject s : sobjRecs){
			sobjMap.put(s.id, s);
			sobjids.add(s.id);
		}
		
		String soql = 'SELECT ';
		
		for(MapWrapper ow : mapData){
			if(objFields.get(ow.columnName) != null){
				soql += objFields.get(ow.columnName) + ',';
			} 
		}
		
		if(soql.contains('LastModifiedDate')){
			soql = soql.removeEnd(',');
		}else{
			soql = soql + ' LastModifiedDate';	
		}
		soql += ' FROM ' + objectName;
		soql += ' WHERE ID in :sobjids';
		
		/* Query salesforce db */
		List<SObject> sfRecs = Database.Query(soql);
		
		for(SObject s : sfRecs){
			sfMap.put(s.id,s);
		}
		
		/* Check to see if LastModifiedDate is greater than Row Created Date. */
		for(String s : sfMap.keySet()){
			if(DateTime.valueof(sfMap.get(s).get('LastModifiedDate')) > DateTime.valueof(idRowMap.get(s).createdAt.substringBeforeLast('-').replace('T',' '))){
				mergeSObjects.add(new MergeWrapper(sfMap.get(s),sobjMap.get(s)));
				for(Integer i=0;i<sobjRecs.size();i++){
					if(sobjRecs[i].id == s){
						sobjectRecs.remove(i);
					}
				}
			}
		}
		
		if(mergeSObjects.size() > 0){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, 
				'There are conflicts for ' + mergeSObjects.size()  +  ' Records'));
			isConflictPresent = true;
		}
	}
	
	/* Method that converts the String to correct Type */
	private Object convertStringToObject(String field,String val){
		
		Object conVal;
			
			if(fieldTypeMap.get(field) == null){
				return null;
			}
			
			if(val == null || val == '' || val == 'null'){
				conVal = null;
				return conVal;
			}
				
			if(fieldTypeMap.get(field) == DisplayType.DATETIME){
				conVal = DateTime.valueOf(val);
			}else if(fieldTypeMap.get(field) == DisplayType.DATE){
				conVal = DateTime.valueOf(val).date();
			}else if(fieldTypeMap.get(field) == DisplayType.DOUBLE || fieldTypeMap.get(field) == DisplayType.PERCENT || fieldTypeMap.get(field) == DisplayType.CURRENCY){ 
				conVal = Double.valueof(val);
			}else if(fieldTypeMap.get(field) == DisplayType.INTEGER){
				conVal = Integer.valueof(val);
			}else{ 
				conVal = val;
			}		
		
		return conVal;
	}
	
	
	/*   Wrapper classes  */
	
	public class MapWrapper {
		
		public String 	columnId 		{get;set;}
		public String 	columnName		{get;set;}
		public String   oFieldName		{get;set;}
		
		public MapWrapper(){
			
		}
		
		public MapWrapper(String cId,String cName){
			
			this.columnId 		= cId;
			this.columnName		= cName;
		}
	}
	
	public class MergeWrapper {
		public SObject salesforceRec  {get;set;}
		public SObject smartSheetRec  {get;set;}
		public String selected		  {get;set;}
		
		public MergeWrapper(SObject sf, SObject sm){
			this.salesforceRec = sf;
			this.smartSheetRec = sm;
			this.selected      = 'Salesforce';
		}
	}
}