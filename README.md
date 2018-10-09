# Emailmerge - send personalised e-mail in bulk

## Synopsis

Create a mail configuration once, 'emailmerge.cfg':

    # SMTP host
    server: mail.example.com
    
    # from address
    from: luke@example.com

Next, create one file with the e-mail contents, say 'mail.txt':

    Dear [% title %] [% lastname %],
    
    It is our pleasure to confirm your RSVP.
    
    Kind regards,
    
    [% sender %]

Create a file with a header with field names, and addresses in
'addresses.csv':

  title;lastname;email
  mr.;Jones;jones@example.com
  professor;Smith;smith@example.com


Now, run

  perl emailmerge.pl -s "RSVP succesful" -t mail.txt -r addresses.csv

This will send an e-mail to mr. Jones and professor Smith with the
template filled in.


## Description

Emailmerge is useful for sending personalised e-mail in bulk. You draft
your e-mail as plain text, with placeholders for the fields that you need
to personalise. You then supply a CSV file with a header with the field
names, and one line for each address.


## Configuration file

The configuration file must be placed in the same directory as where you
run emailmerge.pl.

The following options are recognised:

  host
    The SMTP server that you will be connecting to.

  ssl
    The SSL type to connect to the SMTP server; either 'starttls', 'ssl'
    or empty. If you need SSL, it is probably 'starttls'.

  sasl_username
    Username to be used for authentication, if you need it.

  sasl_password
    Password to be used for authentication, if you need it.

  from
    Address to be used as "From"; if you will only send e-mail from one
    address, you can specify it here. You can also specify the From
    address on the command line, which overrides the 'from' setting here.


## Command-line arguments

The following command-line arguments are recognised:

  -r

  --recipients   The file with e-mail recipients


  -t

  --template     The file with the e-mail template

  -s
  --subject      The subject of the e-mail

  -R
  --reply-to     The reply-to address (optional)


## Automatic fields

A few fields are set automatically, and should not be used as a column in the recipients file:

  sender
    The 'from'-address, taken from the configuration file, or from the command-line.


## Caveats

When exporting from Excel, Excel tends to create CSV files with
byte-order marking (BOM). These are three bytes at the start of the file.
The current version cannot handle these yet. Use an editor like VIM to
remove the BOM bytes. In VIM, open the file, then do 

  :set nobomb
  :wq


## Version

This is version 1.0.

