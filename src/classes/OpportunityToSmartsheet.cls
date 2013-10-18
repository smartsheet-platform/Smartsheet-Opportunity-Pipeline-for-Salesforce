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
 //   public boolean showMappings                     {get;set;}
    public boolean clickedOnce                      {get;set;}
    
    // Defined to just hold dates
    public Opportunity opp1                         {get;set;}
    public Opportunity opp2                         {get;set;}
    public List<Opportunity> oppRecords             {get;set;}
    
    public String  selectedOption                   {get;set;}
    public boolean isExportSelected                 {get;set;}
  
    // Private 
    private List<OpportunityPipelineConstants.Sheet> sheets;  
    private OpportunityPipelineConstants.Result newSheet;
    private Apexpages.StandardSetController setCon;
    private Map<String,String> columnIdNameMap;
    private Map<String,String> opportunityFields;
    private Map<String,String> opportunityLabels;
    private Map<String,Schema.DisplayType> oppFieldTypeMap;
    private Map<String,List<String>> fieldPicklistsMap;
    
    private final String SHEET_NAME = 'Opportunity Pipeline ' + String.valueof(System.now());
       
    // Constructor - currently set on the standardsetController so that the button can be displayed on the List Views of Opportunity
    public  OpportunityToSmartsheet(Apexpages.StandardSetController controller){
        sheets = new List<OpportunityPipelineConstants.Sheet>();
        mapData = new List<OpportunityMapWrapper>();
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
            
        if(OpportunityPipelineConstants.getAccessToken() == null || OpportunityPipelineConstants.getAccessToken() == ''){
                String noTokenMessage = 'No Access Token Found. Make sure obtain a token by registering your ';
            noTokenMessage += 'Smartsheet account for a third-party app in the Developer Tools settings ';
            noTokenMessage += 'of the Smartsheet UI. Use the access token in the Custom Settings of this ';
            noTokenMessage += 'Salesforce application.';
                    
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, noTokenMessage));
            return;
        }
            
        if(OpportunityPipelineConstants.VERSIONURL == null || OpportunityPipelineConstants.VERSIONURL == '')
            OpportunityPipelineConstants.VERSIONURL = '/1.1'; // Uses 1.1 as Default
        
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
    
    /*
            Generate the report for the Opportunity Pipeline with filters
    */
    public void report(){
        String soql = 'SELECT Id, Name, StageName, Type, Probability FROM Opportunity';
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
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, 'Your query returned more than 5,000 records. Smartsheet restricts a sheet to 5,000 rows. Please filter your results before trying to export to Smartsheet'));
            return;        	
        }
                   
    }
        
    /*
            Send the data to Smartsheet. Since Smartsheet supports only 1 row insert, check the size of records and if less than 10 iterate over the number of records 
            else perform a batch process to send the data.
    */
    public void sendToSmartsheet(){
              
        if(oppRecords == null || oppRecords.size() == 0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, 'Nothing to send '));
            return;
        }
            
        setFields();
        for(OpportunityMapWrapper om : mapData){
            if(om.oFieldName != null || om.oFieldName != ''){
                om.columnName = opportunityLabels.get(om.oFieldName);
            }
        }
        
        createSheet();                
        doSend(oppRecords);
            
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Smartsheet ' + newSheet.name + ' created. Go<a href="' + newSheet.permaLink + '" target="_blank">here</a>to view the sheet.'));
        clickedOnce = true;    
    }
        
    private void createSheet(){
        List<OpportunityPipelineConstants.Columns> cols = new List<OpportunityPipelineConstants.Columns>();
        
        for(OpportunityMapWrapper om : mapData){
            OpportunityPipelineConstants.Columns col = new OpportunityPipelineConstants.Columns();
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
            
        OpportunityPipelineConstants.Smartsheet nSheet = new OpportunityPipelineConstants.Smartsheet();
        
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
            String endpoint = OpportunityPipelineConstants.APIDOMAIN + OpportunityPipelineConstants.VERSIONURL + OpportunityPipelineConstants.SHEETSURL;
            String jsonBody = HttpUtil.sendSmartsheetReq('POST', JSON.serialize(nSheet), endpoint);         
            OpportunityPipelineConstants.SheetResponse resp = (OpportunityPipelineConstants.SheetResponse)JSON.deserialize(jsonBody,OpportunityPipelineConstants.SheetResponse.class);
            
            if(resp.message == 'SUCCESS' && resp.resultCode == 0){
                newSheet = resp.result;
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Error with Smartsheet ' + resp.message)); 
                return;
            }
            
            mapData = new List<OpportunityMapWrapper>();
            
            for(OpportunityPipelineConstants.Columns cl : newSheet.columns){
                mapData.add(new OpportunityMapWrapper(cl.Id,cl.title));
            }
            
            // Perform the auto match with Opportunity Field labels.
            if(mapData.size() > 0) {
                autoMatch();
            }
                                
        }catch(SmartsheetException e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Error getting templates from Smartsheet ' + e.getMessage()));
        }
    }
    
    /* 
            Called from SendToSmartSheet method above, sends one opportunity record at a time.
    */
        
        private void doSend(List<Opportunity> opps){
            String endpoint = OpportunityPipelineConstants.APIDOMAIN + OpportunityPipelineConstants.VERSIONURL + OpportunityPipelineConstants.SHEETURL + '/' + newSheet.Id + '/rows';
            List<OpportunityPipelineConstants.Rows> allCells = new List<OpportunityPipelineConstants.Rows>();
            List<OpportunityPipelineConstants.RowData> allRows = new List<OpportunityPipelineConstants.RowData>();
            
            for(Opportunity o : opps){
                allCells = new List<OpportunityPipelineConstants.Rows>();
                OpportunityPipelineConstants.RowData newR = new OpportunityPipelineConstants.RowData();
                
                for(OpportunityMapWrapper om : mapData){
                    if(om.oFieldName != null && om.oFieldName != ''){
                        OpportunityPipelineConstants.Rows newRow = new OpportunityPipelineConstants.Rows();                               
                        newRow.columnId = om.columnId;
                        newRow.value = String.valueof(o.get(om.oFieldName));
                        newRow.strict = false;
                        allCells.add(newRow);   
                    }
                }
                newR.cells = allCells;
                allRows.add(newR);
            }
            
            OpportunityPipelineConstants.RowWrapper smartSheetData = new OpportunityPipelineConstants.RowWrapper();
            smartsheetData.rows = allRows; 
            smartsheetData.toBottom = true;
            
            String reqBody = JSON.serialize(smartsheetData);
            
            try {           
                String jsonBody = HttpUtil.sendSmartsheetReq('POST', reqBody, endpoint);
                system.debug('Response ' + jsonBody);   
            }catch(SmartsheetException e){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Problem posting to Smartsheet: ' + e.getMessage()));
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
        Sets the default fields for Sheet without Template 
    */
    
    public void setFields(){
            
        mapData.add(new OpportunityMapWrapper(null,'Opportunity ID','Id'));
        mapData.add(new OpportunityMapWrapper(null,'Name','Name'));
        mapData.add(new OpportunityMapWrapper(null,'Stage','StageName'));
        mapData.add(new OpportunityMapWrapper(null,'Opportunity Type','Type'));
        mapData.add(new OpportunityMapWrapper(null,'Probability (%)','Probability'));
    }
    
    public void addRow(){
        mapData.add(new OpportunityMapWrapper());
    }
    
    public void removeRow(){
        mapData.remove(mapData.size()-1);
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
        for(integer i=0;i<10;i++){
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
            
        public String   columnId                {get;set;}
        public String   columnName              {get;set;}
        public String   oFieldName              {get;set;}
        
        public OpportunityMapWrapper(){
                
        }
        
        public OpportunityMapWrapper(String cId,String cName){
            this.columnId = cId;
            this.columnName = cName;
        }
        
        public OpportunityMapWrapper(String cId, String cName, String fieldName){
            this.columnId = cId;
            this.columnName = cName;
            this.oFieldName = fieldName;
        }
        
    }
}