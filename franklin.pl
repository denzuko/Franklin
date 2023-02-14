#!/usr/bin/perl
use Irssi;
use strict;
use vars qw($VERSION %IRSSI);
use warnings;
use LWP::UserAgent;
use URI;
use JSON;
use Digest::MD5 qw(md5_hex);
use Encode;
my $httploc   = "/var/www/html/said/";
my $webaddr   = "https://gpt3.oxasploits.com/said/";
my $wordlimit = "250";
my $hardlimit = "340" - length($webaddr) + 10;
$VERSION = "2.0a3";
%IRSSI = (
           authors     => 'oxagast',
           contact     => 'marshall@oxagast.org',
           name        => 'franklin',
           description => 'Support script for Franklin GPT3 bot',
           license     => 'BSD',
           url         => 'http://gpt3.oxasploits.com',
           changed     => 'Feb, 14th 2023',
);
our $apikey;
open( AK, '<', "api.key" ) or die $!;

while (<AK>) {
  $apikey = $_;
}
$apikey =~ s/\n//g;
chomp($apikey);
close(FH);
Irssi::signal_add_last( 'message public', 'frank' );
Irssi::print "Franklin: $VERSION loaded";
Irssi::print "Franklin: API key: $apikey";

sub callapi {
  my ( $textcall, $server, $nick, $channel ) = @_;
  my $url   = "https://api.openai.com/v1/completions";
  my $model = "text-davinci-003";
  my $heat  = "0.7";
  my $uri   = URI->new($url);
  my $ua    = LWP::UserAgent->new;
  my $askbuilt =
      "{\"model\": \"$model\",\"prompt\": \"$textcall\","
    . "\"temperature\":$heat,\"max_tokens\": $wordlimit,"
    . "\"top_p\": 1,\"frequency_penalty\": 0,\"presence_"
    . "penalty\": 0}";
  $ua->default_header( "Content-Type"  => "application/json" );
  $ua->default_header( "Authorization" => "Bearer " . $apikey );
  my $res = $ua->post( $uri, Content => $askbuilt );

  if ( $res->is_success ) {
    my $json_rep  = $res->decoded_content();
    my $json_decd = decode_json($json_rep);
    my $said      = $json_decd->{choices}[0]{text};
    $said =~ s/^\n+//;
    my $hexfn = substr(
                        Digest::MD5::md5_hex(
                                                utf8::is_utf8($said)
                                              ? Encode::encode_utf8($said)
                                              : $said
                        ),
                        0, 8
    );
    umask(0133);
    open( SAID, '>', "$httploc$hexfn" ) or die $!;
    print SAID "$nick asked $textcall\n<---- snip ---->\n$said $webaddr$hexfn";
    close(SAID);
    my $said_cut = substr( $said, 0, $hardlimit );
    Irssi::print "Franklin: Reply: $said $webaddr$hexfn";
    $server->command("msg $channel $said_cut $webaddr$hexfn");
    return 0;
  }
  else {
    Irssi::print "Franklin: Something went wrong.";
    return 1;
  }
}

sub frank {
  my ( $server, $msg, $nick, $address, $channel ) = @_;
  if ( $msg =~ /^Franklin: (.*)/ ) {
    my $textcall = $1;
    Irssi::print "Franklin: $nick asked: $textcall";
    my $wrote = 1;
    while ( $wrote == 1 ) {
      $wrote = callapi( $textcall, $server, $nick, $channel );
    }
  }
}
