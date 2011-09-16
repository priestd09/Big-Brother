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
my $findcm_url = $root_url . 'findnetfriends.php'; # which we got from this url
my $tries = 0;

login($email, $password);
find_classmates('California', 2005);
logout();

sub get_content {
	my $url = $_[0];
	$url =~ s/&amp;/&/g; # Decode &, so that URLs are actually correct 

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
	get_content($index_url);

	my $response = $mech->submit_form(
	  fields => {
	    'email' => $_[0],
	    'pass'  => $_[1]
	  }
	);
}

sub logout {
	my $content = get_content($index_url);

	if ($content =~ /(logout\.php.+?)"/) {
		get_content($root_url . $1);
	}
}

sub find_classmates {
	get_content($findcm_url);

	# Using click() instead of submit_form()
	# From the FAQ: 'Try using $mech->click() instead of $mech->submit() or vice-versa.'
	#
	# Proposal: use click() all the time now?
	#
	$mech->form_number(1);
	$mech->set_fields('sf_text_field' => $_[0], 'sf_year_field' => $_[1]);
	my $response = $mech->click();
	#
	# To do: pick a random school + classmates 
	#
	add_high_school();
}

# Subroutine to add the high school to the profile
#
# To do: supply randomly picked school and year
#
sub add_high_school {
	get_content('http://m.facebook.com/editprofile/exp/edu/index.php?st=10');

	$mech->form_number(1);
	my $high_school = 'California High School'; # No supply from find_classmates() yet.
	$mech->field('query', $high_school);
	my $response = $mech->click();

	if ($response->decoded_content =~ /<a href="\/(editprofile.+?)">$high_school/) {
		get_content($root_url . $1);
	}
	
	$mech->form_number(1);
	my $grad_year = 2005;
	$mech->field('grad_year', $grad_year);
	$response = $mech->click();
}


# This is more of a debugging function, it checks for the names and values in all the forms on a webpage
# I used it to check whether I was on the right page or not
sub check_forms {
	my @forms = $mech->forms() or die "Error!\n";
	foreach (@forms) {
		print "\n";
		my $form = $_;
		my @names = $form->param();
		foreach (@names) {
			print "$_\n";
			my @values = $form->param($_);
			foreach (@values) {
					print "\t$_\n";
			}
		}
	}
}

# no use for this yet but maybe in the future? :)
sub post_status {
	my $content = get_content($profile_url);
	my $response = $mech->submit_form(
		fields => { status => shift }
	); 
	die $response->status_line unless $response->status_line;
}
