import boto3
import json
import os
from google import genai
from datetime import datetime, timedelta

# 1. Initialize Modern Gemini AI Client
api_key = os.environ.get("GEMINI_API_KEY")
if not api_key:
    print("ERROR: Please set your GEMINI_API_KEY environment variable.")
    exit(1)

client = genai.Client(api_key=api_key)

# 2. Initialize AWS CloudTrail Client
cloudtrail = boto3.client('cloudtrail', region_name='us-east-1')

def get_recent_aws_events():
    print("[*] Fetching recent AWS activity logs from CloudTrail...")
    start_time = datetime.now() - timedelta(hours=1)
    
    response = cloudtrail.lookup_events(
        StartTime=start_time,
        MaxResults=20
    )
    
    events = []
    for event in response.get('Events', []):
        cloudtrail_event = json.loads(event['CloudTrailEvent'])
        events.append({
            "EventName": cloudtrail_event.get("eventName"),
            "UserIdentity": cloudtrail_event.get("userIdentity", {}).get("arn", "Unknown"),
            "SourceIP": cloudtrail_event.get("sourceIPAddress"),
            "EventTime": cloudtrail_event.get("eventTime")
        })
    return events

def analyze_with_ai(events):
    print("[*] Sending logs to Gemini AI for security analysis...\n")
    
    prompt = f"""
    You are a Senior Cloud Security Operations (SOC) Analyst for an enterprise.
    Analyze the following AWS CloudTrail logs. 
    
    1. Summarize what infrastructure was created, modified, or accessed.
    2. Identify any potential security risks (e.g., are there permissive firewall rules, or is the root user being used?).
    3. Output the response in a professional, easy-to-read Markdown format tailored for a Chief Information Security Officer (CISO).
    
    Logs to analyze:
    {json.dumps(events, indent=2)}
    """
    
    # Using the new SDK syntax and the 2.0-flash model
    response = client.models.generate_content(
        model='gemini-3.8-flash',
        contents=prompt
    )
    
    print("==================================================")
    print("           AI SOC ANALYST REPORT                  ")
    print("==================================================")
    print(response.text)

if __name__ == "__main__":
    recent_events = get_recent_aws_events()
    
    if not recent_events:
        print("No events found. Note: CloudTrail can sometimes take 5-10 minutes to process new events. Try again shortly.")
    else:
        analyze_with_ai(recent_events)