#!/usr/bin/perl
use strict;
use warnings;

use HTTP::Cookies;
use WWW::Mechanize;

my $mech = WWW::Mechanize->new;
$mech->agent_alias('Linux Mozilla');
$mech->cookie_jar(HTTP::Cookies->new());
#$mech->proxy('http', 'http://localhost:8118'); # Use TOR proxy

my $email = 'coudraep@deagot.com';
my $password = 'haidermary';

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
	# - if we're gonna add multiple schools per account, check for duplicate schools and classmates
	#

	get_content($findcm_url);

	# Using click() instead of submit_form()
	# From the FAQ: 'Try using $mech->click() instead of $mech->submit() or vice-versa.'
	$mech->form_number(1);
	$mech->set_fields('sf_text_field' => $_[0], 'sf_year_field' => $_[1]);
	my $response = $mech->click();
	my $content = $response->decoded_content; # Can't apply while (regex) on $response->decoded_content itself

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

	$mech->form_number(1);
	$mech->set_fields('radio_field' => $radio_value);
	$response = $mech->click("radio_submit");
    
    
    my @frnd_cb_names;
    my @frnd_cb_values;

    my $pages = int(rand(5)); # go through random amount of pages
    for (my $count = 0; $count <= $pages; $count++) {
        $content = $response->decoded_content;

        if ($content =~ /(We found \d+ people who went to your high school.)/) {
            print $1. "\n" unless $count; # if it's the first loop, print it out.
        } else {
            print "Couldn't find anyone from our high school.";
            last;
        }

        while ($content =~ /name="(checkboxids_\d)_uid" value="(\d+)"/g) {
            push(@frnd_cb_names, $1); # friend checkbox names
            push(@frnd_cb_values, $2); # friend checkbox values
        }

        $random = int(rand(4)); # add $random amount of...
        my $random2 = int(rand(9)); # ...random friends
        $mech->form_number(1);
        my $form = $mech->current_form();

        for ($count = 0; $count <= $random; $count++) {
            $form->find_input($frnd_cb_names[$random2])->check();
            print "Added one person\n"; # maybe would be cool if we printed the name?
            $random2 = int(rand(9));
        }

        # maybe sleep here a bit? would look more human-like.
        $response = $mech->click("bf_submit");
    }
	
	# Update the profile with the appropriate information
	add_high_school($high_school, $_[1]);
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
	$mech->click();
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

