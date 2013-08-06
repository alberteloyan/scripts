#! /usr/bin/perl
use strict;

########################################################################
# 
# File   :  uploadFilesToWeb.pl
# Author :  Albert Eloyan
# E-mail :  alber.eloyan@gmail.com
#
########################################################################
#
# This script mechanized upload of images to a static website
# Provided login credentials and environment
# Input: file to be uploaded
# Output: string URL 
# 
########################################################################

use WWW::Mechanize;
use HTTP::Cookies;
use warnings;
use CGI;
use URI::Escape;
use HTML::DOM;
use JSON qw( decode_json );


my $DEBUG_MESSAGES = undef;
my $EXECUTION_MODE = 'stage';

#In order to be able to upload files, you need a valid account 
#foe each of the environments.
#Please add a login_credentials.txt file to this directory
#The format should be json (e.g. '{prod: {username: 'something', ...}, stage: {...}})
#The script will defaule to these values if no credentials provided

my $input_file = "login_credentials.txt";
open( my $input_fh, "<", $input_file ) || die "Can't open $input_file: $!";

my $jsonCredentials = join('', <$input_fh>);
my $decodedJsonCredentials = decode_json($jsonCredentials);

if ($EXECUTION_MODE eq 'prod') {

    if ($decodedJsonCredentials) {
        our ($username) = $decodedJsonCredentials->{'prod'}{'username'};
        our ($password) = $decodedJsonCredentials->{'prod'}{'password'};
    } else {
        our ($username)  = 'albertosmad@gmail.com';
        our ($password)  = "random33";
    }

    our ($photoUrl) = "http://phpadmin.tagged.com/photo_upload.html";
    our ($loginUrl) = "http://secure.tagged.com/secure_login.html";
    our ($galleryUrl) = "http://www.tagged.com/photo_gallery.html";
}
elsif ($EXECUTION_MODE eq 'stage') {

    if ($decodedJsonCredentials) {
        our ($username) = $decodedJsonCredentials->{'stage'}{'username'};
        our ($password) = $decodedJsonCredentials->{'stage'}{'password'};
    } else {
        our ($username)  = 'aeloyan+hemingway@tagged.com';
        our ($password)  = "random33";
    }

    our ($photoUrl) = "http://phpadmin.tag-stage.com/photo_upload.html";
    our ($loginUrl) = "http://secure.tag-stage.com/secure_login.html";
    our ($galleryUrl) = "http://www.tag-stage.com/photo_gallery.html";
}
else {

    if ($decodedJsonCredentials) {
        our ($username) = $decodedJsonCredentials->{'local'}{'username'};
        our ($password) = $decodedJsonCredentials->{'local'}{'password'};
    } else {
        our ($username)  = 'aeloyan+kafka@tagged.com';
        our ($password)  = "random33";
    }

    our ($photoUrl) = "http://phpadmin.tag-local.com/photo_upload.html";
    our ($loginUrl) = "http://secure.tag-local.com/secure_login.html";
    our ($galleryUrl) = "http://www.tag-local.com/photo_gallery.html";
}
#-------------------------------------------

foreach (@ARGV) {

    #click the button
    my $mech = WWW::Mechanize->new();
    $mech->cookie_jar(HTTP::Cookies->new());

    if ($DEBUG_MESSAGES) {
        print "PRE_URL.....................................OK \n";
    }   

    #main::loginUrl are the globals defined above
    eval {$mech->get($main::loginUrl)};
    print "FAIL_GET\n" if $@;

    if ($DEBUG_MESSAGES) {
        print "POST_URL....................................OK \n";
    }

    #look at the page source and get the right element name
    $mech->form_name('login');
    $mech->field(username => $main::username);
    $mech->field(password => $main::password);
    $mech->submit();

    if ($DEBUG_MESSAGES) {
        print "CREDENTIALS.................................OK \n";
    }

    eval {$mech->get($main::photoUrl)};
    print "FAIL_GET\n" if $@;

    if ($DEBUG_MESSAGES) {
        print "AUTHENTICATED...............................OK \n";
    }

    #again, just tune this to the wspecific website DOM
    $mech->form_name('uploadfile');
    $mech->field('upload_photo' => $_);
    
    eval {$mech->submit()};
    print "FAIL_POST\n" if $@;

    #print $mech->content;

    if ($DEBUG_MESSAGES) {
        print "PHOTO UPLOADED..............................OK \n";
    }

    #decoding the URL string
    my $responseString = uri_unescape($mech->content());

    #regexing the trequired link out of it
    my $re1='.*?';
    my $re2='(\\{.*?\\})';

    my $jsonObject;
    my $re=$re1.$re2;
    if ($responseString =~ m/$re/is) {
            $jsonObject=$1;
    }

    #finally extracting the URL from the JSON object
    my $decoded_jsonObject = decode_json($jsonObject."}");

    if (my $newImageSource = $decoded_jsonObject->{'result'}{'url'}) {
        print $newImageSource."\n\n";        
    }
    else {
        print "FAIL_SMALL\n";
    }

}   