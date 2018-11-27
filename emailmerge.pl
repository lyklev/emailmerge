#!/usr/bin/env perl
#
# vim: set ts=2 sw=2 expandtab :
#
use utf8;
use strict;
use warnings;

use Email::MIME;
use Email::Sender;
use Email::Sender::Simple qw(try_to_sendmail);
use Email::Sender::Transport::SMTP qw();
use Email::Sender::Transport::SMTP::Persistent;
use YAML ();
use Getopt::Long;
use Template;


# read options

my $mail_template_file;
my $recipients_file;
my $from_address;
my $reply_to_address;
my $subject;
my $verbose;
my $dry_run;
my $sleep;
my $help;

Getopt::Long::Configure ("bundling");

GetOptions(
  "template|t=s"     => \$mail_template_file,
  "recipients|r=s"   => \$recipients_file,
  "from|f=s"         => \$from_address,
  "reply-to|R=s"     => \$reply_to_address,
  "subject|s=s"      => \$subject,
  "help|h"           => \$help,
  "verbose|v"        => \$verbose,
  "dry-run"          => \$dry_run,
  "sleep"            => \$sleep,
) or die("error in command line arguments");

unless (
  defined $mail_template_file &&
  defined $recipients_file    &&
  defined $from_address       &&
  defined $subject            ||
  defined $help
) {
  print("Missing arguments; usage:\n",
    "  --template <email template file>\n",
    "  --from     <from address>\n",
    "  --subject  <subject>\n",
    "  [--reply-to  <reply-to address>]\n");
  exit;
}

# read fixed configuration

my $cfg = "";
if (open(CFG, "<emailmerge.cfg")) {
  $cfg = join("", <CFG>);
  close(CFG);
}
else {
  warn("no configurion file found or readable; using empty config");
}

my $cfg_hashref = YAML::Load($cfg);

# open and read the list of recipients
my @recipients;

open(RCPTS, "<$recipients_file")
  or die("cannot open or read '$recipients_file'");

my $header_line = <RCPTS>;
chomp($header_line);
my @field_names = split(/;/, $header_line);

my $line_no = 1;
while (my $line = <RCPTS>) {
  chomp($line);
  $line_no++;

  my @fields = split(/;/, $line);
  
  if ($#fields != $#field_names) {
    print(STDERR "*** error on line no $line_no: expected " ,
      $#field_names + 1 , " ,got ", $#fields + 1, "\n");
    exit(1);
  }
  my %rec;
  @rec{@field_names} = @fields;
  push(@recipients, \%rec);
  print($rec{'email'}, "\n");
}

close(RCPTS);

# send the actual e-mails

my $tt = Template->new();

my $mail_transport = Email::Sender::Transport::SMTP::Persistent -> new(
  host             => $cfg_hashref -> {'host'},
  ssl              => $cfg_hashref -> {'ssl'},
  sasl_username    => $cfg_hashref -> {'username'},
  sasl_password    => $cfg_hashref -> {'password'},
);

my @failed_recipients;

for my $recipient (@recipients) {
  $recipient -> {'sender'}   = $from_address;
  $recipient -> {'reply-to'} = $reply_to_address;
  my $mail_body;
  my $rv = $tt -> process($mail_template_file, $recipient, \$mail_body);
  unless ($rv) {
    print("Error:", $tt -> error(), "\n");
    exit(1);
  }

  if ($verbose) {
    print("Mail body to ", $recipient->{'lastname'}, 
      " follows:\n", "-" x 72, "\n", $mail_body, "-" x 72, "\n");
  }

  my $email = Email::MIME->create(
    attributes => {
      content_type => "text/plain",
      # disposition  => "attachment",
      #charset      => "US-ASCII",
      charset       => 'UTF-8',
    },
    header => [
      From      => $from_address,
      To        => $recipient -> {'email'},
      Subject   => $subject,
    ],
    body => $mail_body,
  );
  $email -> encoding_set ('base64');

  if ($verbose) {
    print("-" x 72, "\n",
      "To     :", $recipient -> {'email'}, "\n",
      "Subject:", $subject, "\n",
      $mail_body);
  }
  unless ($dry_run) {
    my $rv = try_to_sendmail(
      $email,
      {
        transport  => $mail_transport,
      }
    );
    unless ($rv) {
      push(@failed_recipients, $recipient -> {'email'});
    }

  }
  if (defined $sleep) {
    sleep $sleep;
  }
} # next email

print("Failed recipients:\n");
for my $failed_recipient (@failed_recipients) {
  print("$failed_recipient\n");
}

