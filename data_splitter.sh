input_column_value=$1
input_sheet_id=$2
input_sheet_name=$3

#get client data
client_id="179515599858-lk0cga5d3ons8hvldgfolbftbhjfccl6.apps.googleusercontent.com"
client_secret="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"

#get authentication code
token_uri="https://oauth2.googleapis.com/token"
redirect_uri="urn:ietf:wg:oauth:2.0:oob"
auth_uri="https://accounts.google.com/o/oauth2/auth"
scope="https://www.googleapis.com/auth/spreadsheets"
url="${auth_uri}?scope=${scope}&include_granted_scope=true&response_type=code&redirect_uri=${redirect_uri}&client_id=${client_id}"


#provide url to get authentication code
echo ""
echo ""
echo ""
echo "Copy paste URL in browser"
echo ""
echo ""
echo $url

echo ""
echo ""
echo "Wait ....."
echo "Wait ....."
echo ""
echo ""

#read authentication code
echo "enter authentication code"
read auth_code


#get token file using authentication code
token=$(curl -s -X POST "${token_uri}" \
        -d "client_id=${client_id}" \
        -d "client_secret=${client_secret}" \
        -d "code=${auth_code}" \
        -d "redirect_uri=${redirect_uri}" \
        -d "grant_type=authorization_code")


#read access token value in below code
access_token=$(echo $token | grep -oP '[\"]access_token[\"]\s*:\s*[\"][^\"]*[\"]')
access_value=$(echo $access_token | grep -oP '[\"][^access_token][\w\W]*[\"]')
access_value=$(echo $access_value | tr -d ' "' | tr -d ':')

echo ""
echo ""
echo ""



#get sheet using access token and id
range="${input_sheet_name}!A1:D6"

sheet_value=$(curl -s -H "Authorization: Bearer ${access_value}" \
        "https://sheets.googleapis.com/v4/spreadsheets/${input_sheet_id}/values/${range}")
#echo $sheet_value > got-sheet-test







#try to get columns here
sheet_column_row=$sheet_value


first_row=$(echo ${sheet_column_row} | grep -oP '[\[]\s*[\[][^\]]*')
first_row=$(echo ${first_row} | tr -d '[' | tr -d ' "')

c=0
IFS=',' read -ra firstrow <<< ${first_row}
for first_row_element in ${firstrow[@]}
do
        ((c++))
done
echo "total number of columns: $c"





#get spread sheet

file=$sheet_value
#extract after values
value=$(echo $file | grep -oP '[\"]values[\"]\s*:\s*[\[]\s*[\w\W]*[\]]')
#extract 2d-list of values
list=$(echo $value | grep -oP '[\[]\s*[\"][\w\W]*[\"]\s*[\]]')
#remove all []
values=$(echo "$list" | tr -d '[] ')
#remove all quotes
noquotes=$(echo "$values" | tr -d '"')
#done till here

#inserting all words of json i,e. values into matrix
IFS=',' read -ra elements <<< "$noquotes"

declare -A mat





#got to change and edit to make columns
#echo "no of columns: "
#read c


row=0
col=0
for element in ${elements[@]};
do
        mat[$row,$col]=$element
        #echo "$row,$col: ${mat[$row,$col]}"
        ((col++))
        if [[ $col -eq c ]]
        then
                col=0
                ((row++))
        fi
done
#row stores total rows in file
((row--))


#unwanted
#shows column Names present in google sheet
for((i = 0; i <= $row; i++));
do
        res=""
        for(( j = 0; j < $c; j++));
        do
                res+=" ${mat[$i,$j]}"
        done
done

res=""
for((i = 0; i < $c; i++));
do
        res+=" ${mat[0,$i]}"
done

#gets column name for processing
#get index value for column name
column_name=$input_column_value


#find the index of the column name specified
column_name=$(echo $column_name | tr -d ' ')
target=0
for element in $res;
do
        if [[ $element = $column_name ]]
        then
                break
        else
                ((target++))
        fi
done


echo "column name is column no: ${target}"

#demo to get unique values from the column values provided the column name
unique_list=""

for((i = 1; i <= $row; i++));
do
        column_value="${mat[$i,$target]}"
        if grep -q "${column_value}" <<< ${unique_list};
        then
                continue
        else
                unique_list+=" ${column_value}"
        fi
done


IFS=' ' read -ra unique_list_elements <<< $unique_list


#create files for each unique values
list_of_files=""
for element in ${unique_list_elements[@]};
do
        touch "${element}"
        list_of_files+=" ${element}"
done

#get row and insert entire row of the matrix if column value matches required
#store in file matching the name
for((i = 0; i <= $row; i++));
do
        storage_file="${mat[$i,$target]}"
        res=""
        for((j = 0; j < $c; j++));
        do
                res+=" ${mat[$i,$j]}"
        done
        echo "$res" >> $storage_file
done



IFS=' ' read -ra list_files <<< $list_of_files


#prepare final payload
result_payload='{"values": ['
result_payload+="[ \"$column_name\", \"Sheet_Id\", \"URLs\"] "
touch new_spreadsheet_details

#make payload for all files
for element in ${list_files[@]};
do
        payload='{"values": ['
        while IFS= read -r line;
        do
                payload+=' ['
                IFS=' ' read -ra words <<< "$line"
                for word in "${words[@]}";
                do
                        payload+="\"$word\","
                done
                payload="${payload%,}"
                payload+='],'
        done < "$column_name"
        while IFS= read -r line;
        do
                payload+=' ['
                IFS=' ' read -ra words <<< "$line"
                for word in "${words[@]}";
                do
                        payload+="\"$word\","
                done
                payload="${payload%,}"
                payload+='],'
        done < "$element"

        payload="${payload%,}"
        payload+='] }'
        rm $element

        #request to create new spreadsheet
        this_spreadsheet=$(curl -s -X POST -H "Authorization: Bearer ${access_value}" \
        -H "Content-Type: application/json"\
        --data "{\"properties\": {\"title\": \"${element}\"}}" \
        "https://sheets.googleapis.com/v4/spreadsheets")

        this_spreadsheet_id=$(echo ${this_spreadsheet} | grep -oP '[\"]spreadsheetId[\"]:\s*[\"][^\"]*[\"]')
        this_spreadsheet_id=$(echo ${this_spreadsheet_id} | grep -oP '[\"][^spreadsheetId][\w\W]*[\"]')
        this_spreadsheet_id=$(echo ${this_spreadsheet_id} | tr -d ' :' | tr -d '"')
        this_spreadsheet_url=$(echo ${this_spreadsheet} | grep -oP 'https:[^\"]*')

        result_payload+=", [\"$element\", \"$this_spreadsheet_id\", \"$this_spreadsheet_url\" ] "
        curl -s -H "Authorization: Bearer $access_value" -H "Content-Type: application/json" --data-raw "$payload" "https://sheets.googleapis.com/v4/spreadsheets/$this_spreadsheet_id/values/Sheet1!A1:append?valueInputOption=USER_ENTERED"
done

#result_payload="${result_payload%,}"
result_payload+='] }'
echo ""
echo ""
rm ${column_name}
#echo "$result_payload"
curl -s -H "Authorization: Bearer $access_value" -H "Content-Type: application/json" --data-raw "$result_payload" "https://sheets.googleapis.com/v4/spreadsheets/$input_sheet_id/values/Result!A1:append?valueInputOption=USER_ENTERED"