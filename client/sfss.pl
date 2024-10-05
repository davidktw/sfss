#!/usr/bin/env perl

use strict;
use warnings;
use LWP::UserAgent;
use IO::Socket::SSL;
use URI::Escape;
use Data::Dumper;
use JSON::XS;
use File::Path qw(make_path);

my $SFSS_CONFIG_PATH           = "$ENV{HOME}/.sfss";
my $SFSS_PROP_PATH             = "$SFSS_CONFIG_PATH/config";
my $SFSS_PREFIX                = 'https://___SFSS_SERVER_HOSTNAME___/sfss';
my $SFSS_REGISTER_URL          = "$SFSS_PREFIX/register";
my $SFSS_DELETE_URL            = "$SFSS_PREFIX/delete";
my $SFSS_UPLOAD_URL            = "$SFSS_PREFIX/upload";
my $SFSS_DOWNLOAD_URL          = "$SFSS_PREFIX/download";
my $SFSS_LIST_URL              = "$SFSS_PREFIX/list";
my $GITHUB_CLIENTID            = '___GITHUB_CLIENTID___';
my $GITHUB_DEVICECODE_URL      = 'https://github.com/login/device/code';
my $GITHUB_GET_ACCESSTOKEN_URL = 'https://github.com/login/oauth/access_token';

if (! -f $SFSS_PROP_PATH) {
  make_path("$ENV{HOME}/.sfss");
  open(my $FH, ">$SFSS_PROP_PATH");
  print $FH encode_json({});
  close($FH);
}

my $prop;
open(my $FH, "<$SFSS_PROP_PATH");
$prop = do { local $/; decode_json(<$FH>); };

my $access_token = $prop->{access_token};

my $ua = new LWP::UserAgent;
$ua->ssl_opts(
    SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE,
    verify_hostname => 0
);

my $command = $ARGV[0] || '';
##################################################
# REGISTRATION
##################################################
if ($command eq 'register') {

  # device flow
  my $res = $ua->post($GITHUB_DEVICECODE_URL, {
      client_id => $GITHUB_CLIENTID,
      scope     => 'user'
    });
  my $content = $res->decoded_content;
  my %data = ();
  while ($content =~ /([^&=]+)=([^&]+)/g) {
    $data{$1} = uri_unescape($2);
  }
  print <<"EOM";
==================
REGISTRATION STEPS
==================
1) Please open the browser to $data{verification_uri} .
2) Sign in to your github account, and enter the following code: $data{user_code} .
3) Authorize the access to the app sfss to complete the registration.

EOM

  my $starttime = time;
  my $registered;
  $|++;
  while ((time - $starttime) < $data{expires_in}) {
    my $res = $ua->post($GITHUB_GET_ACCESSTOKEN_URL, {
        client_id   => $GITHUB_CLIENTID,
        device_code => $data{device_code},
        grant_type  => 'urn:ietf:params:oauth:grant-type:device_code'
      });
    my $content = $res->decoded_content;
    my($access_token) = $content =~ /access_token=([^&]+)/;
    if ($access_token) {
      my $res = $ua->post($SFSS_REGISTER_URL, {
        access_token  => $1
      });
      my $content = $res->decoded_content;
      print "\n$content";
      $registered = 1;

      $prop->{access_token} = $access_token;
      open(my $FH, ">$SFSS_PROP_PATH");
      print $FH encode_json($prop);
      close($FH);
      
      last;
    }
    else {
      print "\rPending activation. (left ".($data{expires_in} - time + $starttime)." secs)";
      sleep($data{interval});
    }
  }
  print "Timeout. Please restart registration process." unless ($registered);

}
##################################################
# UPLOAD
##################################################
elsif ($command eq 'upload') {
  die("Missing access token. Please register first using '$0 register'.\n") unless ($access_token);
  my $filepath = $ARGV[1] || '';
  die("Please specific $0 upload <filepath to upload>.\n") unless ($filepath);
  die("Missing file $filepath.\n") unless (-f $filepath);

  my $res = $ua->post(
    $SFSS_UPLOAD_URL,
    Content_Type => 'form-data',
    Content      => {
      access_token  => $access_token,
      filename      => $filepath,
      file          => [ $filepath ]
  });

  if ($res->code == 200) {
    my $content = $res->decoded_content;
    print "$content";
  } else {
    print "Failed upload - ".$res->status_line."\n";
  }
}
##################################################
# DOWNLOAD
##################################################
elsif ($command eq 'download') {
  die("Missing access token. Please register first using '$0 register'.\n") unless ($access_token);
  my $filepath = $ARGV[1] || '';
  die("Please specific $0 download <filename to download>.\n") unless ($filepath);

  my $res = $ua->post(
    $SFSS_DOWNLOAD_URL,
    Content_Type => 'form-data',
    Content      => {
      access_token  => $access_token,
      filename => $filepath
  });

  if ($res->code == 200) {
    if ($res->content_type eq 'application/octlet') {
      my $filename = $res->filename;
      my $proceed  = 1;
      if (-f $filename) {
        print "$filename already exist locally, overwrite ? (Y/y/N/n) ? ";
        my $reply = <STDIN>;
        $proceed = $reply =~ /^[Yy]/;
      }
      if ($proceed) {
        open(my $outfh, ">$filename");
        print $outfh $res->content;
        close($outfh);
        print "Successfully saved '$filename'\n";
      }
      else {
        print "Skip saving '$filename'\n";
      }
    }
    else {
      my $content = $res->decoded_content;
      print "$content";
    }
  } else {
    print "Failed download - ".$res->status_line."\n";
  }
}
##################################################
# DELETE
##################################################
elsif ($command eq 'delete') {
  die("Missing access token. Please register first using '$0 register'.\n") unless ($access_token);
  my $filepath = $ARGV[1] || '';
  die("Please specific $0 delete <filename to delete>.\n") unless ($filepath);

  my $res = $ua->post(
    $SFSS_DELETE_URL,
    Content_Type => 'form-data',
    Content      => {
      access_token  => $access_token,
      filename => $filepath
  });
  my $content = $res->decoded_content;
  print "$content";
}
##################################################
# LIST
##################################################
elsif ($command eq 'list') {
  die("Missing access token. Please register first using '$0 register'.\n") unless ($access_token);

  my $res = $ua->post($SFSS_LIST_URL, {
    access_token  => $access_token
  });

  if ($res->code == 200) {
    my $content = $res->decoded_content;
    print "$content";
  } else {
    print "Failed list - ".$res->status_line."\n";
  }
}
else {
  my $scriptnamelen = length($0);
  my $scriptnamepad = ' 'x$scriptnamelen;
  print <<"EOM";
Usage:
  $0 register            - Register using your own github account
$scriptnamepad                         to use secure file storage system(SFSS).
  $0 list                - List the uploaded files in SFSS.
  $0 upload <filename>   - Upload file to SFSS.
  $0 download <filename> - Download file from SFSS.
  $0 delete <filename>   - Delete file in SFSS.
EOM
}

# vim: sw=2 st=2 ts=2 et number si
