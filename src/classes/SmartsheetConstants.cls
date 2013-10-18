/***************************************************************************
 	Name: SmartsheetConstants.cls 
 	Description: Holds all the constants and returns the required Smartsheet 
 				Auth Tokens from Custom Settings.
 				
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

public with sharing class SmartsheetConstants {
    public static final String APIDOMAIN = 'https://api.smartsheet.com';
   	public static String VERSIONURL   = '/1.1';
    public static final String SHEETSURL    = '/sheets';
    public static final String SHEETURL     = '/sheet';  

    
    public static String getAccessToken(){
        
    	return Smartsheet_IO__c.getOrgDefaults().AccessToken__c;
    }
    
    public class Sheet {
        
        public String id                {get;set;}
        public String name              {get;set;}
        public String accessLevel       {get;set;}
        public String description       {get;set;}
        
    }
    
    public class SheetResponse {
        
        public String message       {get;set;}
        public Result result        {get;set;}
        public Integer resultCode   {get;set;}
                
    }
    
    public class Result {
        
        public String accessLevel    {get;set;}
        public List<Columns> columns {get;set;}
        public String id             {get;set;}
        public String name           {get;set;}
        public String permalink      {get;set;}
    }
    
    
    public class Columns {
        
        public String id                {get;set;}
        public Integer index            {get;set;}
        public Boolean primary          {get;set;}
        public String title             {get;set;}
        public String type              {get;set;}
        public List<String> options     {get;set;}
        public String symbol            {get;set;}
        
    }

    public class Rows {
        public String columnId          {get;set;}
        public String value             {get;set;}
        public boolean strict           {get;set;}
    }
    
    public class SheetContent {
        
        public String accessLevel       {get;set;}
        public List<Columns> columns    {get;set;}
        public String createdAt         {get;set;}
        public String id                {get;set;}
        public String modifiedAt        {get;set;}
        public String name              {get;set;}
        public String permalink         {get;set;}
        public List<Rows> rows          {get;set;}
        public String version           {get;set;}
        
    }
    
    /* Wrapper class to send multiple rows at same time. */
    
    public class RowWrapper {
        public boolean toTop      {get;set;}
        public boolean toBottom   {get;set;}
        public boolean parentId   {get;set;}
        public boolean siblingId  {get;set;}
        public List<RowData> rows {get;set;}
    }
    
    public class RowData {
        public List<Rows> cells         {get;set;}
    }
    
    public class Smartsheet {
        public String name {get;set;}
        public List<Columns> columns {get;set;}
    }
    
    
    /*--- For Import ---*/
    
    public class ColumnsImp {
        public String id;
        public Integer index;
        public String title;
        public String type;
        public Boolean primary;
    }

    public class RowsImp {
        public String id;
        public Integer rowNumber;
        public List<CellsImp> cells;
        public String createdAt;
        public String modifiedAt;
    }

    public class CellsImp {
        public String type;
        public String value;
        public String columnId;
    }
    
    public class SmartsheetImp {
        public String id;
        public String name;
        public List<ColumnsImp> columns;
        public List<RowsImp> rows;
        public String accessLevel;
        public Integer version;
        public String permalink;
        public String createdAt;
        public String modifiedAt;
    }
     

}