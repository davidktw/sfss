#!/usr/bin/perl

package Common;
use base 'Exporter';
use MIME::Base64;
use LWP::UserAgent;
use JSON::XS;
use Crypt::CBC;
use Data::Dumper;
use Log::Log4perl;

our @EXPORT = qw(
  $DBFILE
  $GITHUB_APPNAME
  $GITHUB_CLIENTID
  $GITHUB_CLIENTSECRET
  $GITHUB_GET_ACCESSTOKEN_URL
  $GITHUB_CHECKTOKEN_URL
  $SFSS_DATADIR
  $SFSS_COMMON_SECRET
  $SFSS_LOGCONF
  github_checktoken
  github_isvalid
  sfss_encrypt_fh
  sfss_decrypt_fh
);

# load the server side configuration
our $SFSS_CONFIG;
our $SFSS_PREFIX                = '/opt/sfss';
our $SFSS_DATADIR               = "$SFSS_PREFIX/data";
our $SFSS_CONFIG_PATH           = "$SFSS_PREFIX/config";
our $SFSS_LOGCONF               = "$SFSS_CONFIG_PATH/log4perl.conf";
our $SFSS_DBFILE                = "$SFSS_PREFIX/db/sfss.sqlite";
our $SFSS_COMMON_SECRET         = 'sample common secret';

my $SFSS_CONFIG_FILE = "$SFSS_CONFIG_PATH/config";
eval {
  local $/;
  open(my $infh, "<$SFSS_CONFIG_FILE") or die($!);
  $SFSS_CONFIG = decode_json(scalar(<$infh>)) or die($!);
  close($infh);
};
if ($@) {
  print STDERR "$@";
  $SFSS_CONFIG = {};
}

our $GITHUB_APPNAME             = $SFSS_CONFIG->{APPNAME};
our $GITHUB_CLIENTID            = $SFSS_CONFIG->{CLIENTID};
our $GITHUB_CLIENTSECRET        = $SFSS_CONFIG->{CLIENTSECRET};
our $GITHUB_GET_ACCESSTOKEN_URL = 'https://github.com/login/oauth/access_token';
our $GITHUB_CHECKTOKEN_URL      = "https://api.github.com/applications/$GITHUB_CLIENTID/token";

sub github_checktoken($) {
  my($access_token) = @_;
	my $ua  = new LWP::UserAgent;
	my $req = new HTTP::Request('POST', $GITHUB_CHECKTOKEN_URL);
	$req->header('Content-Type'  => 'application/json');
	$req->header('Authorization' => 'BASIC '.encode_base64("$GITHUB_CLIENTID:$GITHUB_CLIENTSECRET", ''));
	$req->content("{\"access_token\": \"$access_token\"}");
	my $res     = $ua->request($req);
	my $content = $res->decoded_content;
	my $ghobj   = decode_json($content);
  return $ghobj;
}

sub github_isvalid($) {
  my($ghobj) = @_;
  return defined($ghobj->{id} && $ghobj->{app}{name} eq $GITHUB_APPNAME);
}

sub sfss_encrypt_fh($$$) {
  my($infh, $outfh, $secret) = @_;

  my $cipher = new Crypt::CBC(
    -pass   => $secret,
    -pbkdf  => 'pbkdf2',
    -cipher => 'Cipher::AES'
  );

  $cipher->start('encrypt');
  my $buffer;
  while (read($infh, $buffer, 1024)) {
    print $outfh $cipher->crypt($buffer);
  }
  print $outfh $cipher->finish;
}

sub sfss_decrypt_fh($$$) {
  my($infh, $outfh, $secret) = @_;

  my $cipher = new Crypt::CBC(
    -pass   => $secret,
    -pbkdf  => 'pbkdf2',
    -cipher => 'Cipher::AES'
  );

  $cipher->start('decrypt');
  my $buffer;
  while (read($infh, $buffer, 1024)) {
    print $outfh $cipher->crypt($buffer);
  }
  print $outfh $cipher->finish;
}

1;

# vim: sw=2 st=2 ts=2 et number si
