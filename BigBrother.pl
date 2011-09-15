#!/usr/bin/perl
use strict;
use warnings;

use HTTP::Cookies;
use WWW::Mechanize;

my $mech = WWW::Mechanize->new;
$mech->agent_alias('Linux Mozilla');
$mech->cookie_jar(HTTP::Cookies->new());
$mech->proxy('http', 'http://localhost:8118'); # Use TOR proxy

my $email = 'username@mail.com';
my $password = 'password';

# We use Facebook for mobile because it's easier to deal with
my $root_url = 'http://m.facebook.com/';
my $index_url = $root_url . 'index.php';
my $profile_url = $root_url . 'profile.php';
my $connect_url = $root_url . 'connect.php?id='; # followed with id number
my $findfr_url = $root_url . 'findfriends.php'; # which we got from this url
my $tries = 0;

login($email, $password);
logout();

sub get {
	my $url = $_[0];
	$mech->get($url);
	$tries ++;
	if ($tries < 3) {
		get() unless ($mech->success());
	}
	$tries = 0;
}

sub login {
	get($index_url);

	my $response = $mech->submit_form(
	  fields => {
	    email => $_[0],
	    pass => $_[1]
	  }
	);
}

sub logout {
	get($index_url);
	my $content = $mech->content();

	my $logout;
	if ($content =~ /(logout\.php.+?)"/) {
		$logout = $1;
	}
	
	get($root_url . $logout);
}

# Not yet in use subs

sub find_friends {
	get($findfr_url);
	my $content = $mech->content();

	while ($content =~ /connect\.php\?id=(\d+)&/g) {
		print $1. "\n";
		push(@_, $1);
		print "Lol\n";
	}

	return @_;
}

# no use for this yet but maybe in the future? :)
sub post_status {
	get($profile_url);
	my $response = $mech->submit_form(
		fields => { status => shift }
	); 
	die $response->status_line unless $response->status_line;
}
