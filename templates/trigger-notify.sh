#!/bin/bash

#Author : songhanpoo
#Contact: hieunlp@fpt.com.vn
#Phone  : 0933312394
#webhook-poo test333

# Contructor
webhook='https://outlook.office.com/webhook/b2302627-c7d5-4287-8082-1c0351b4fbd6@4ebc9261-871a-44c5-93a5-60eb590917cd/IncomingWebhook/2772bedc3aac4f0eaf9c549d10207ad2/07df46ff-9b86-4ebe-826a-c9a3ee15cb47'
api_send_mail='http://systemapi.fpt.vn/api/SystemBulkMailApi/SendMailAttachment'
proxy='http://proxy.hcm.fpt.vn:80/'
api_eslasticsearch='http://172.27.11.201:9200/octopus/_doc'
date=$(date +"%d-%m-%y")

SVC=$1
STATUS=$2
# IP=${ifconfig en0 | grep inet | grep -v inet6 | cut -d" " -f2}


function send_logs_es()
{
    local NAMELOGS=$1
    local TYPE=$2
    local TIMESTAMP=$3
    local STATUS=$4
    curl -i -X POST -H 'Content-Type: application/json' \
    -d "{
            \"name\": \"$NAMELOGS\",
            \"type\": \"$TYPE\",
            \"created_at\":\"$TIMESTAMP\",
            \"status\": $STATUS
    }" $api_eslasticsearch
}

function send_logs_influxdb(){
    
    local NAMELOGS=$1
    local TYPE=$2
    local STATUS=$3
    
    curl -i -XPOST 'http://172.27.11.201:8086/write?db=octopusSvc' --data-binary "$TYPE,name=$NAMELOGS status=$STATUS"

}


function send_logs_pushgateways()
{
    local NAMELOGS=$1
    local TYPE=$2
    local STATUS=$3
    local URL="http://172.27.11.212:9091/metrics/job/octopus/type/$TYPE/name/$NAMELOGS/date/$date_type1/month/$month"

cat << EOF | curl --data-binary @- $URL
  status $STATUS
EOF

}

#function send nortify to microsoft team with webhook
function nortify_msteam()
{
    # nortify_msteam TITLE PROJECTNAME IMAGE NAME VALUE DATE
    local TITLE=$1
    local PROJECTNAME=$2
    local IMAGE=$3 #https://teamsnodesample.azurewebsites.net/static/img/image1.png
    local NAME=$4
    local VALUE=$5
    local NAME2=$6
    local VALUE2=$7
    local DATE=$8

    json="{\"subjects\":\"Hello Boy\",\"message\":\"tesst\",\"recipient_list\":\"songhanpoo@gmail.com\",\"bcc\":\"songhanpoo@gmail.com\"}"

    curl -x $proxy -i -X POST -H 'Content-Type: application/json' \
    -d "{
            \"@type\": \"MessageCard\",
            \"themeColor\": \"D5212E\",
            \"summary\":\"$TITLE\",
            \"sections\": [{
                    \"activityTitle\": \"$TITLE\",
                    \"activitySubtitle\": \"$PROJECTNAME\",
                    \"activityImage\": \"$IMAGE\",
                    \"facts\": [{
                    \"name\": \"$NAME\",
                    \"value\":\"<p>$VALUE</p>\"
                    },{
                    \"name\": \"IP SRV\",
                    \"value\":\"<p>$(ifconfig eth0 | grep inet | grep -v inet6 | awk '{print $2}')</p>\"
                    },{
                \"name\": \"Date\",
                \"value\": \"$DATE\"
            }],
                    \"markdown\": true
            }]
    }" $7
}

#function send mail with post json to api fpt
function nortify_mail()
{
    # nortify_mail ALIAS_MAIL MAIL_TO MAIL_CC TITLE_MAIL
    #Template mail static css in style
    #    MAIL_TO=$1
    #    MAIL_CC=$2
    # TITLE_MAIL=$3
    #       BODY=$4
            
    local before="<html lang='en'><head></head><body><div style='display: flex; justify-content:center; align-items: center;'></div><div style='display: flex; justify-content:center; align-items: center;'> <div> <table> <tr><th style='border: 1px solid #0e0d0d;text-align: left;padding: 8px;'>Log Name</th> <th style='border: 1px solid #0e0d0d;text-align: left;padding: 8px;'>File Name</th> <th style='border: 1px solid #0e0d0d;text-align: left;padding: 8px;'>Date</th> </tr>"
    after="</table> </div></div><br/><p>Thông tin liên hệ: ftel.bigdata.sys@fpt.com.vn </p><p>Email được gửi tự động từ hệ thống giám sát Big Data phục vụ cho việc chủ động thông báo khi phát hiện thiếu dữ liệu.<br /> Trân Trọng.</p></body></html>"

    curl -i -X POST -H 'Content-Type: application/json' \
    -d "{
            \"FromEmail\": \"webmaster@fpt.vn\",
            \"FromMailAlias\":\"FTEL.BIGDATA.SYS\",
            \"Recipients\": \"$1\",
            \"CarbonCopys\": \"$2\",
            \"BlindCarbonCopys\":\"\",
            \"Subject\": \"[FTEL-BIGDATA] Warning $3 $date\",
            \"Body\": \"$before$4$after\",
            \"isBodyhtml\":1
    }" $api_send_mail
}

if [ -z "$SVC" ] || [ -z "$STATUS" ]; then
  echo "Missing param for use this scripts"
else
  nortify_msteam "Warning  $SVC" "Send Form keepalived Kong Cluster" "https://teamsnodesample.azurewebsites.net/static/img/image1.png" "$SVC status" "$STATUS" "$(date)" $webhook
  # nortify_mail $MAIL_TO $MAIL_CC "Warning $SVC" "$STATUS"

fi