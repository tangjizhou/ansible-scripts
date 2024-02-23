import smtplib
from email.mime.text import MIMEText
from email.header import Header

sender = 'alertmanager@xx.xx.com'
receiver = 'alex@xx.xx.com'
mail_pass = 'Swx@777.com'

text = 'test'
message = MIMEText(text, 'plain', 'uft-8')

message['From'] = Header(sender, 'utf-8')
message['To'] = Header(receiver, 'utf-8')

subject = 'subject test'
message['Subject'] = Header(subject, 'utf-8')

try:
    smtpObj = smtplib.SMTP('10.8.192.48', 587)
    smtpObj.starttls()
    smtpObj.login(sender, mail_pass)
    smtpObj.sendmail(sender, receiver, message.as_string())
    print('success')
except smtplib.SMTPException as e:
    print('Error:', e)