/***************************************************************************
 Name: OpportunityToSmartsheet 
 VisualForce Page: OpportunityToSmartsheet
 Description: Controller Class for OpportunityToSmartsheet Visualforce page
 Operations: Does the following to integrate with Smartsheet REST API
 
 1. get the sheet /sheet/{sheetid}
 2. insert rows into sheet /sheet/{sheetid}/rows
 3. delete sheet /sheet/{sheetid}  
 
     
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

public with sharing class OpportunityToSmartsheet {
        
    public String sheetName                         {get;set;}
    public List<OpportunityMapWrapper> mapData      {get;set;}
    public String selectedStage                     {get;set;}
    public String selectedProb                      {get;set;}      
    public boolean clickedOnce                      {get;set;}
    
    // Defined to just hold dates
    public Opportunity opp1                         {get;set;}
    public Opportunity opp2                         {get;set;}
    public List<Opportunity> oppRecords             {get;set;}
    
    public String  selectedOption                   {get;set;}
    public String  selectedAuthType                 {get;set;}
    public boolean isExportSelected                 {get;set;}
    public boolean isOAuthSelected                  {get;set;}
    public boolean isAuthenticated                  {get;set;}
    public boolean showDeleteTokenLink              {get;set;}
    public String deleteTokenMessage                {get;set;}

    public boolean isNotLoggedIn                 	{get;set;}
  	public String token {
		get {
			if (token == null)
				return 'No Access Token Found.';
			return token;
		}
		set; 
	}
  	public String authType { get; set; }
	public String generatedToken { get; set; }
	
	public List<SelectOption> getAuthTypeList() {
		return AUTH_TYPE_LIST;
	}

	  
    // Private 
    private List<Smartsheet.Sheet> sheets;  
    private Smartsheet.Sheet newSheet;
    private Apexpages.StandardSetController setCon;
    private Map<String,String> columnIdNameMap;
    private Map<String,String> opportunityFields;
    private Map<String,String> opportunityLabels;
    private Map<String,Schema.DisplayType> oppFieldTypeMap;
    private Map<String,List<String>> fieldPicklistsMap;
    
    private final String SHEET_NAME = 'Opportunity Pipeline ' + String.valueof(System.now());
    private String oauthState;
    private SmartsheetApi api;       
    
   
 	private static List<SelectOption> AUTH_TYPE_LIST = new SelectOption[] {
		new SelectOption('OAuth2.0', 'OAuth 2.0'),
		new SelectOption('UserGeneratedToken', 'User Generated Token')
	};  
       
    // Constructor - currently set on the standardsetController so that the button can be displayed on the List Views of Opportunity
    public  OpportunityToSmartsheet(Apexpages.StandardSetController controller){
        sheets = new List<Smartsheet.Sheet>();
        oppRecords = new List<Opportunity>();
        columnIdNameMap = new Map<String,String>();
        opportunityFields = new Map<String,String>();
        opportunityLabels = new Map<String,String>();
        oppFieldTypeMap = new Map<String,Schema.DisplayType>();
        fieldPicklistsMap = new Map<String,List<String>>();
        sheetName = SHEET_NAME;
        opp1 = new Opportunity();
        opp2 = new Opportunity();
        clickedOnce = false;
        showDeleteTokenLink = false;
        isOAuthSelected = true;
        deleteTokenMessage = 'Disconnect from Smartsheet';
        authType = 'OAuth2.0';
        mapData = new List<OpportunityMapWrapper>();
        
        api = new SmartsheetApi();
		User u = [SELECT Access_Token__c FROM User WHERE Id = :UserInfo.getUserId()];
		token = u.Access_Token__c;
		
        /*
         * Getting Opportunity field values and labels and put in a Map
         */
        Map<String, Schema.SObjectField> fieldMap = Opportunity.getSObjectType().getDescribe().fields.getMap();
        
        for(Schema.SObjectField f : fieldMap.values()){
            opportunityFields.put(f.getDescribe().getLabel(),f.getDescribe().getName());
            opportunityLabels.put(f.getDescribe().getName(),f.getDescribe().getLabel());
            oppFieldTypeMap.put(f.getDescribe().getName(),f.getDescribe().getType());
                
            if(f.getDescribe().getType() == Schema.DisplayType.PICKLIST){
                List<String> picklists = new List<String>();
                for(Schema.PicklistEntry p : f.getDescribe().getPicklistValues()){
                    picklists.add(p.getValue());
                }
                fieldPicklistsMap.put(f.getDescribe().getName(),picklists);
            }
        }
    }

	/* 
	 * start OAuth flow by redirecting user to Smartsheet authorization URL 
	 */
	public PageReference authenticate() {
		if (authType.equals('UserGeneratedToken')) {
			if (generatedToken != null && !generatedToken.equals(''))
				updateToken(generatedToken);
			else {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,
						'Generated Token is empty, please set the user generated token in the Generated Token field'));
			}
		} else {	
			/*
			 * OAuth
			 * 
			 * create random, save it to User object
			 */
			oauthState = '' + Crypto.getRandomLong();
			User u = [SELECT Id, OAuth_State__c FROM User WHERE Id = :UserInfo.getUserId()];
			u.OAuth_State__c = oauthState;
			
			try {
				update u;
			} catch (DmlException e) {
				System.debug('Failed to update User, ' + e.getMessage());
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,
						'Failed to update User object, please try again'));
			}
			
			String authUrl = api.getRequestAuthCodeUrl(oauthState);
			PageReference authPage = new PageReference(authUrl);
			authPage.setRedirect(true);
			return authPage;
		}
		return null;
	}

	private void updateToken(String newToken) {
		User u = [SELECT Access_Token__c, Refresh_Token__c, Token_Expires__c FROM User WHERE Id = :UserInfo.getUserId()];
		u.Access_Token__c = newToken;
		u.Refresh_Token__c = null;
		u.Token_Expires__c = null;
		try {
			update u;
		} catch (DmlException e) {
			System.debug('Failed to update User, '+ e.getMessage());
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,
				'Failed to update User object, please try again'));
		}
		token = newToken;
		api = new SmartsheetApi();
	}    
    
    public List<SelectOption> getAllOptions(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','-- Select Option --'));
        options.add(new SelectOption('Import','Import'));
        options.add(new SelectOption('Export','Export'));
        return options;
    }
    
    public void importExport(){
        if(selectedOption == 'Export'){
            isExportSelected = true;
        }else if(selectedOption == 'Import'){
            isExportSelected = false;
        }
    }
    
    public void authTypeSelect(){
        if(authType.equals('OAuth2.0')) {
            isOAuthSelected = true;
        } else {
            isOAuthSelected = false;
        }
    }
    
    public void toggleDeleteToken(){
        if(showDeleteTokenLink) {
           showDeleteTokenLink = false;
           deleteTokenMessage = 'Disconnect from Smartsheet';
        } else {
           showDeleteTokenLink = true;
           deleteTokenMessage = 'Go Back to Import/Export';
        }
    }

    
	/* 
	 * Smartsheet OAuth redirect_url is set to the VF page. When Smartsheet makes callback,
	 * this oauthTarget() method is get called.
	 */
	public PageReference oauthTarget() {
		/* 
		 * retrieve oauth state from User object
		 */
		User u = [SELECT Id, OAuth_State__c FROM User WHERE Id = :UserInfo.getUserId()];
		oauthState = u.OAuth_State__c;
		
		String code = ApexPages.currentPage().getParameters().get('code');
		String state = ApexPages.currentPage().getParameters().get('state');
		String error = ApexPages.currentPage().getParameters().get('error');

		if (code == null && state == null && error == null) {
			/* 
			 * Regular VF visit, not OAuth callback
			 */
			return null;
		}
		
		/* 
		 * check state
		 */
		if (error != null) {
			System.debug('oauthTarget: non-null error returned ' + error);
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,
					'Smartsheet API error returned: ' + error));
			
			//throw new SmartsheetException('oauthTarget: non-null error returned, ' + error);
		} else if (state == null || !state.equals(oauthState)) {
			System.debug('oauthTarget: state is null or does not match, ' + state);
			throw new SmartsheetException('oauthTarget: state is null or does not match, ' + state);
		} else {
			/*
			 * requesting authroization code is successful
 			 *
			 * request access token
			 */
			Smartsheet.AccessToken accessToken = api.getAccessToken(code);
			token = accessToken.access_token;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,
					'Logged in to Smartsheet successfully'));
			
		}
		return null;
	}
	/* 
	 * action method to delete current token
	 */
	public PageReference deleteToken() {
		updateToken(null);
		ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,
				'Deleted access token, please login again to use Smartsheet API'));
		return null;
	}

    
    
    /*
     *	Generate the report for the Opportunity Pipeline with filters
     */
    public void report(){
        String soql = 'SELECT Id, Name, StageName, Type, Probability, Amount FROM Opportunity';
        String whrClause = '';
        
        if(selectedStage != null && selectedStage != ''){
            whrClause += ' StageName = \'' + String.escapeSingleQuotes(selectedStage) + '\' AND ';
        }
        
        if(selectedProb != null && selectedProb != ''){
            whrClause += ' Probability ' + selectedProb + ' AND ';          
        }
        
        if(opp1.CloseDate != null){
            whrClause += ' CloseDate > ' + String.valueof(opp1.CloseDate) + ' AND ';
        }
        
        if(opp2.CloseDate != null){
            whrClause += ' CloseDate < ' + String.valueof(opp2.CloseDate) + ' AND ';
        }            
        
        if(whrClause != ''){
            soql = soql + ' WHERE ' + whrClause.removeEnd(' AND ');
        }
        
        oppRecords = Database.query(soql);      
        clickedOnce = false;
        /*
            Checks Record set to make sure it's under smartsheet row limit of 5000
        */
        if(oppRecords.size() >= 5000){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, 
                'Your query returned more than 5,000 records. Smartsheet restricts a sheet to 5,000 rows. Please filter your results before trying to export to Smartsheet'));
            return;         
        }
                   
    }
        
    /*
        Send the data to Smartsheet. Since Smartsheet supports only 1 row insert, check the size of records and if less than 10 iterate over the number of records 
        else perform a batch process to send the data.
    */
    public void sendToSmartsheet(){
        Long newSheetId;
              
        if(oppRecords == null || oppRecords.size() == 0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, 'Nothing to send '));
            return;
        }
            
        // re-initialize mapData
        if(mapData.size() > 0){
	        mapData = new List<OpportunityMapWrapper>();
        }
            
        setFields();
        
        for(OpportunityMapWrapper om : mapData){
            if(om.oFieldName != null || om.oFieldName != ''){
                om.columnName = opportunityLabels.get(om.oFieldName);
            }
        }
        
        // Create New Blank Sheet in Smartsheet
        newSheetId = createSheet();
                        
        // Populate the newly created sheet
        doSend(oppRecords, newSheetId);
            
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 
            'Smartsheet ' + newSheet.name + ' created. Go<a href="' + newSheet.permaLink + '" target="_blank">here</a>to view the sheet.'));
        clickedOnce = true;  

    }
        
    private Long createSheet() {
        List<Smartsheet.Column> cols = new List<Smartsheet.Column>();
        
        for(OpportunityMapWrapper om : mapData){
            Smartsheet.Column col = new Smartsheet.Column();
            col.title = om.columnName;
                
            if(om.oFieldName == 'Id'){
                col.primary = true;
            }
            
            if(oppFieldTypeMap.get(om.oFieldName) == DisplayType.PICKLIST){
                col.type = 'PICKLIST';
                col.options = fieldPicklistsMap.get(om.oFieldName);
            }else if(oppFieldTypeMap.get(om.oFieldName) == DisplayType.Boolean){
                col.type = 'CHECKBOX';
            }else if(oppFieldTypeMap.get(om.oFieldName) == DisplayType.Date){
                col.type = 'DATE';
            }else{
                col.type = 'TEXT_NUMBER';
            }    
            
            cols.add(col);
        }

        Smartsheet.Sheet nSheet = new Smartsheet.Sheet();
        /*
                Checks the value of new sheetName. Assigns SHEET_NAME constant if sheetName is null or blank
        */
        if(sheetName != null && sheetName.length() > 0){
            nSheet.name = sheetName;
        } else {
            nSheet.name = SHEET_NAME;
        }
        nSheet.columns = cols;
        
    	
    	try {
            /*
                POST to Create the Sheet first
            */
            nSheet.rows = null;
            
            if(Test.isRunningTest()){
                HttpClient.testResponse = TestHelper.getNewSheetResponse(true);
                Smartsheet.SheetResult createResult = (Smartsheet.SheetResult)JSON.deserialize(HttpClient.testResponse.getBody(), Smartsheet.SheetResult.class);
	            
	            if(createResult.message == 'SUCCESS' && createResult.resultCode == 0){
	            	newSheet = createResult.result;
	            }else{
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 
	                    'Error with Smartsheet ' + createResult.message)); 
	                return 0;
	            }
            } else {
                // create sheet
                Smartsheet.SheetResult createResult = api.createSheet(nSheet);

	            if(createResult.message == 'SUCCESS' && createResult.resultCode == 0){
	                newSheet = createResult.result;
	            }else{
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 
	                    'Error with Smartsheet ' + createResult.message)); 
	                return 0;
	            }
            }
            
            mapData = new List<OpportunityMapWrapper>();
            
            for(Smartsheet.Column cl : newSheet.columns){
                mapData.add(new OpportunityMapWrapper(cl.Id, cl.title));
            }

            /*
             * Perform the auto match with Opportunity Field labels.
             */

            if(mapData.size() > 0) {
                autoMatch();
            }
         
            /*
             * Return the id of the newly created sheet
             */
            return newSheet.id;                    
      }catch(SmartsheetException e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 
                'Error creating a sheet in Smartsheet ' + e.getMessage()));
            return 0;
        }
    }
    
    /* 
        Called from SendToSmartSheet method above, sends one opportunity record at a time.
    */
    
    private void doSend(List<Opportunity> opps, Long sheetId){
        List<Smartsheet.Row> allRows = new List<Smartsheet.Row>();

        for(Opportunity o : opps) {
            // create row obj for each o
            List<Smartsheet.Cell> rowCells = new List<Smartsheet.Cell>();
            Smartsheet.Row newRow = new Smartsheet.Row();

            for(OpportunityMapWrapper om : mapData) {
                if(om.oFieldName != null && om.oFieldName != '') {
                    /*
                     * Build Cell Objects
                     */
                    Smartsheet.Cell newCell = new Smartsheet.Cell();                               
                    newCell.columnId = om.columnId;
                    newCell.value = String.valueof(o.get(om.oFieldName));
                    newCell.strict = false;
                    rowCells.add(newCell);   
                }
            }
            newRow.cells = rowCells;
            allRows.add(newRow);
        }
        
        // InsertRows = RowWrapper

        Smartsheet.InsertRows smartsheetData = new Smartsheet.InsertRows();
        smartsheetData.rows = allRows; 
        smartsheetData.toBottom = true;
        
        try {
        	if(Test.isRunningTest()){
 				HttpClient.testResponse = TestHelper.getInsertRowsResponse(true);
                Smartsheet.RowsResult rowsRes = (Smartsheet.RowsResult)JSON.deserialize(HttpClient.testResponse.getBody(), Smartsheet.RowsResult.class);        	
        	} else {
	            Smartsheet.RowsResult rowsRes = api.insertRows(sheetId, smartsheetData);
        	} 
        }catch(SmartsheetException e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 
                'Problem posting to Smartsheet: ' + e.getMessage()));
        }
    }
    
    /*
        Performs the automatch of the Column Names from Sheet and Opportunity Field Labels. 
    */
    public void autoMatch(){
            
        for(OpportunityMapWrapper ow : mapData){
            if(opportunityFields.get(ow.columnName) != null)
                ow.oFieldName = opportunityFields.get(ow.columnName); 
        }
    }
    
    /*
        Sets the fields for Sheet
    */
    public void setFields(){
            
        mapData.add(new OpportunityMapWrapper(null, 'Opportunity ID','Id'));
        mapData.add(new OpportunityMapWrapper(null, 'Name','Name'));
        mapData.add(new OpportunityMapWrapper(null, 'Stage','StageName'));
        mapData.add(new OpportunityMapWrapper(null, 'Opportunity Type','Type'));
        mapData.add(new OpportunityMapWrapper(null, 'Probability (%)','Probability'));
        mapData.add(new OpportunityMapWrapper(null, 'Amount','Amount'));
    }
    
    public void addRow(){
        mapData.add(new OpportunityMapWrapper());
    }
    
    public void removeRow(){
        mapData.remove(mapData.size() - 1);
    }
    
    /*
        Getter Methods.
    */
    public List<SelectOption> getallStages(){
            
        List<SelectOption> options = new List<SelectOption>();
        List<Schema.PicklistEntry> picklists = Opportunity.getSObjectType().getDescribe().fields.getMap().get('StageName').getDescribe().getPicklistValues();
        
        options.add(new SelectOption('','All'));
        
        for(Schema.PicklistEntry p : picklists){
            options.add(new SelectOption(p.getValue(),p.getLabel()));
        }
        
        return options;
    }
    
    public List<SelectOption> getallProbabilities(){
            
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','All'));
        Integer j = 0;
        for(integer i=0; i<10; i++){
            j += 10;
            options.add(new SelectOption('>'+j,'>'+j));                       
        }
        j = 0;
        for(integer i=0;i<10;i++){
            j += 10;
            options.add(new SelectOption('<'+j,'<'+j));                       
        }
        
        return options;
    }
    
    public List<SelectOption> getOFields(){
        
        List<SelectOption> options = new List<SelectOption>();
        
        options.add(new SelectOption('','-- Select Field --'));
        
        for(String s : opportunityFields.keySet()){
            options.add(new SelectOption(opportunityFields.get(s),s));
        }
        
        return options;
            
    }
    
    /*   Wrapper class  */
    public class OpportunityMapWrapper {
            
        public Long   columnId                {get;set;}
        public String   columnName              {get;set;}
        public String   oFieldName              {get;set;}
        
        public OpportunityMapWrapper(){
                
        }
        
        public OpportunityMapWrapper(Long cId,String cName){
            this.columnId = cId;
            this.columnName = cName;
        }
        
        public OpportunityMapWrapper(Long cId, String cName, String fieldName){
            this.columnId = cId;
            this.columnName = cName;
            this.oFieldName = fieldName;
        }
        
    }
}