## What is this?
The phishing server is a collection of docker scripts and configs that will facilitate the quick creation of a postfix mail server and web client in any given VPS. This allows you to spin up postfix servers easily and quickly.

## Legal Disclaimer

Usage of this phishing server and subsequent scripts for attacking targets without prior mutual consent is illegal. This is only for educational or testing purposes and can only be used where strict consent has been given. It's the end user's responsibility to obey all applicable local, state and federal laws. Developers assume no liability and are not responsible for any misuse or damage caused by this program. Only use for educational or testing purposes.

## How do I use this?

Run the install.sh script on your VPS or VM to get started!

There are some requirements you should know about:

1. You need a domain name. If you dont have one, consider looking at expireddomains.com to find a domian that already has some repulation and categories (Finance, Banking, Tech, etc.).
2. Docker and docker-compose need to be installed on the host.
3. If you intend to use the letsencrypt cert option, ensure your domain's DNS is configured correctly first.
4. A can do attitude and maybe some beer.

## Interesting things

The postfix config is set to strip mail headers from any client by default - those that use 587 to auth and send mail (the only way to send mail on this server). This is done to hide the mail client to avoid any detection. For example, gophish adds headers to identify itself as gophish, which will usually get caught be an email security gateway (think Proofpoint). The postfix server can be instructed to strip these headers from the email to avoid that detection. View the config/postfix/header_checks file for examples on how to block more headers, if needed.

## Special Thanks

I want to thank the entire team at [Focal Point Data Risk](https://focal-point.com/) for giving me the opportunity to research, develop, and test this device and subsequent applications that make up the phishing server as a whole. Without their support and guidance, this idea would have never been possible. Thank you!!!