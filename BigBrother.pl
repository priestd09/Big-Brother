#!/usr/bin/perl
use strict;

use HTTP::Cookies;
use WWW::Mechanize;

my $mech = WWW::Mechanize->new;
$mech->agent_alias('Linux Mozilla');
$mech->cookie_jar(HTTP::Cookies->new());

my $email = 'name@email';
my $password = 'pass';

# We use Facebook for mobile because it's easier to deal with
my $index_url = 'http://m.facebook.com/index.php';
my $profile_url = 'http://m.facebook.com/profile.php';
my $connect_url = 'http://m.facebook.com/connect.php?id='; # followed with id number
my $findfr_url = 'http://m.facebook.com/findfriends.php'; # which we got from this url

login($email, $password);
my @newfriends = find_friends();
# ^ not sure if works, got blocked from fb before testing :(
# should have used proxies.

sub find_friends {
	$mech->get($findfr_url);
	my $content = $mech->content() or die "Error getting findfriends.php content\n";

	while ($content =~ /connect\.php\?id=(\d+)&/g) {
		print $1. "\n";
		push(@_, $1);
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

sub login {
	$mech->get($index_url);

	my $response = $mech->submit_form(
	  fields => {
	    email => @_[0],
	    pass => @_[1]
	  }
	);
	die $response->status_line unless $response->status_line;
	# should add a piece of code here that tells us if we got blocked
	# otherwise it would just stop working and we would have no idea why
}
