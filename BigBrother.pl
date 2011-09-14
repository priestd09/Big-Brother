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
my $get_error = "Error fetching content of ";

login($email, $password);
print "Logged in\n";

logout();
print "Logged out\n";

sub login {
	$mech->get($index_url) or die "$get_error.$index_url\n";

	my $response = $mech->submit_form(
	  fields => {
	    email => $_[0],
	    pass => $_[1]
	  }
	);

	die $response->status_line unless $response->status_line;
	# should add a piece of code here that tells us if we got blocked
	# otherwise it would just stop working and we would have no idea why
}

sub logout {
	$mech->get($index_url) or die "$get_error.$index_url\n";
	my $content = $mech->content();

	my $logout;
	if ($content =~ /(logout\.php(.+?)")/) {
		$logout = $1;
		$logout =~ s/"$//g;
	}
	
	$mech->get($root_url . $logout) or die "Error logging out\n";
}

# Not yet in use subs

sub find_friends {
	$mech->get($findfr_url) or die "Error fetching $findfr_url content\n";
	my $content = $mech->content() or die "$get_error.$findfr_url\n";

	while ($content =~ /connect\.php\?id=(\d+)&/g) {
		print $1. "\n";
		push(@_, $1);
		print "Lol\n";
	}

	return @_;
}

# no use for this yet but maybe in the future? :)
sub post_status {
	$mech->get($profile_url);
	my $response = $mech->submit_form(
		fields => { status => shift }
	); 
	die $response->status_line unless $response->status_line;
}
