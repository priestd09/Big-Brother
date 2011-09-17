#!/usr/bin/perl
use strict;
use warnings;

use HTTP::Cookies;
use WWW::Mechanize;

my $mech = WWW::Mechanize->new;
$mech->agent_alias('Linux Mozilla');
$mech->cookie_jar(HTTP::Cookies->new());
#$mech->proxy('http', 'http://localhost:8118'); # Use TOR proxy

my $email = 'cepithuj@deagot.com';
my $password = '19Rutherford84';

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

	$mech->set_fields('email' => $_[0], 'pass' => $_[1]);
	$mech->click();
}

sub logout {
	my $content = get_content($index_url);

	if ($content =~ /(logout\.php.+?)"/) {
		get_content($root_url . $1);
	}
}

sub find_classmates {
	#
	# To do: 
	# - pick a random classmates 
	# - if we're gonna add multiple schools per account, check for duplicate schools and classmates
	#

	get_content($findcm_url);

	# Using click() instead of submit_form()
	# From the FAQ: 'Try using $mech->click() instead of $mech->submit() or vice-versa.'
	$mech->form_number(1);
	$mech->set_fields('sf_text_field' => $_[0], 'sf_year_field' => $_[1]);
	my $response = $mech->click();
	my $content = $response->decoded_content; # Can't apply while (regex) on $response->decoded_content itself
    
    # a little better to debug
    open (FILE, ">response.html");
	print FILE $content;
    close (FILE);
	my $random = int(rand(10)); # Use the first 10 results, because they make more sense than the others
	my $index = 0;
	my $high_school;
	my $radio_value;
	while($content =~ /id="radio_field" value="(\d+)" \/>(.+?)</g and $random ne 'break') {
		if ($index == $random) {
			$radio_value = $1;
			$high_school = $2;
			$high_school =~ s/&amp;/&/g;
			$random = 'break';
		}
		$index ++;
	}
	# This submit part is still broken
	$mech->form_number(1);
	$mech->set_fields('radio_field' => $radio_value);
	$response = $mech->click("radio_submit");
    
    # a little better to debug
    open (FILE, ">response2.html");
	print FILE $response->decoded_content;
    close (FILE);

	#
	# We're now at the pick classmates screen (if the above wasn't broken
	#
	
	# Update the profile with the appropriate information
	#add_high_school($high_school, $_[1]);
}

# Subroutine to add the high school to the profile
sub add_high_school {
	get_content('http://m.facebook.com/editprofile/exp/edu/index.php?st=10');

	$mech->form_number(1);
	my $high_school = $_[0]; 
	$mech->field('query', $high_school);
	my $response = $mech->click();

	$high_school =~ s/&/&amp;/g;
	if ($response->decoded_content =~ /<a href="\/(editprofile.+?)">$high_school/) {
		get_content($root_url . $1);
	}
	
	$mech->form_number(1);
	$mech->field('grad_year', $_[1]);
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

