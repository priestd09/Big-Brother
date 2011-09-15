#!/usr/bin/perl
use strict;
use warnings;

use HTTP::Cookies;
use WWW::Mechanize;

my $mech = WWW::Mechanize->new;
$mech->agent_alias('Linux Mozilla');
$mech->cookie_jar(HTTP::Cookies->new());
$mech->proxy('http', 'http://localhost:8118'); # Use TOR proxy

my $email = 'username@email.com';
my $password = 'password';

# We use Facebook for mobile because it's easier to deal with
my $root_url = 'http://m.facebook.com/';
my $index_url = $root_url . 'index.php';
my $profile_url = $root_url . 'profile.php';
my $connect_url = $root_url . 'connect.php?id='; # followed with id number
my $findfr_url = $root_url . 'findnetfriends.php'; # which we got from this url
my $tries = 0;

login($email, $password);
find_friends("California", 2005);
logout();

sub get_content {
	my $url = $_[0];
	$mech->get($url);
	$tries ++;
	if (($tries < 3) and (!$mech->success())) {
		print "Failed to get content for: $url\n";
		get_content($url)
	}
	$tries = 0;
	return $mech->content();
}

sub login {
	my $content = get_content($index_url);

	my $response = $mech->submit_form(
	  fields => {
	    email => $_[0],
	    pass => $_[1]
	  }
	);
}

sub logout {
	my $content = get_content($index_url);

	my $logout;
	if ($content =~ /(logout\.php.+?)"/) {
		$logout = $1;
	}
	
	get_content($root_url . $logout);
}

# Not yet in use subs

sub find_friends {
	my $content = get_content($findfr_url);

	my $response = $mech->submit_form(
	  fields => {
	    sf_text_field => $_[0], # search field
		sf_year_field => $_[1] # year field
	  }
	);

	print $response->decoded_content;
}

# no use for this yet but maybe in the future? :)
sub post_status {
	my $content = get_content($profile_url);
	my $response = $mech->submit_form(
		fields => { status => shift }
	); 
	die $response->status_line unless $response->status_line;
}
