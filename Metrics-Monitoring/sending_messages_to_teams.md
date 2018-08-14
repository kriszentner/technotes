# Sending messages programatically to Microsoft Teams:
It's possible to programatically send messages to Microsoft Teams with a fair amount of ease.<sup>[1](#footnote1)</sup>


# Add Webhook
Among the available connectors in the list, you will find Incoming Webhook. This provides an easy solution to post notifications from any scripting language through JSON formatted web service call.

To add the Connector:
	•     Open the Channel and click the More Options button (which appears as three dots at the top right of the window).
	•     Select Connectors.
	•     Scroll down to Incoming Webhook and click the Add button.
	•     Give the connector a name and image of your choosing and finally click Create.
	•     A new unique URI is automatically generated. Copy this URI string to your clipboard.

# Curl Command
```bash
curl --header "Content-Type: application/json" \
  --request POST \
  --data '{"text":"bEEp b0rp bl00p"}' \
   https://outlook.office.com/webhook/0fed5350-dcd8-488d-9893-d63ab7628581@84d266bb-d9f1-4c93-93ee-926820a19484/IncomingWebhook/fb20296ecae84e34a40f141cc99882f7/2cb8b713-2dcd-4921-895a-8ca352bbe9f9
```
# Powershell Command
```powershell
$uri = 'https://outlook.office.com/webhook/0fed5350-dcd8-488d-9893-d63ab7628581@84d266bb-d9f1-4c93-93ee-926820a19484/IncomingWebhook/fb20296ecae84e34a40f141cc99882f7/2cb8b713-2dcd-4921-895a-8ca352bbe9f9'

$body = ConvertTo-JSON @{
    text = 'bEEp b0rp bl00p'
}

Invoke-RestMethod -uri $uri -Method Post -body $body -ContentType 'application/json'
```
# References
<a name="footnote1">1</a>: Greene, Michael (November 2, 2016) [Post notifications to Microsoft Teams using PowerShell](https://blogs.technet.microsoft.com/privatecloud/2016/11/02/post-notifications-to-microsoft-teams-using-powershell/). Technet. Retrieved August 14, 2018
