# bp-split-spreadsheet
<hr>
<p>The data_splitter.sh code needs permission and client id and client secret variables to run</p>

- Run chmod 777 data_splitter.sh to provide necessary permissions to run the code
- Run ./data_splitter.sh Column_Name SpreadsheetID Sheet1 with appropriate values to Column_Name, SpreadsheetID and Sheet1
- The code will split data according to the unique values in the Column_name and make new spreadsheets
- The code will add spreadsheetID and URLs of the new spreadsheet into the Result Sheet of the main spreadsheet
