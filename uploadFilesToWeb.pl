#! /usr/bin/perl
use strict;

########################################################################
# 
# File   :  uploadFilesToTagged.pl
# Author :  Albert Eloyan
# E-mail :  alber.eloyan@gmail.com
#
########################################################################
#
# This script mechanized upload of images to the tagged website
# Provided login credentials and environment (dev,stage,prod)
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


if ($EXECUTION_MODE eq 'prod') {
    our ($username)  = 'albertosmad@gmail.com';
    our ($password)  = "random33";
    our ($photoUrl) = "http://phpadmin.tagged.com/photo_upload.html";
    our ($loginUrl) = "http://secure.tagged.com/secure_login.html";
    our ($galleryUrl) = "http://www.tagged.com/photo_gallery.html";
}
elsif ($EXECUTION_MODE eq 'stage') {
    our ($username)  = 'aeloyan+hemingway@tagged.com';
    our ($password)  = "random33";
    our ($photoUrl) = "http://phpadmin.tag-stage.com/photo_upload.html";
    our ($loginUrl) = "http://secure.tag-stage.com/secure_login.html";
    our ($galleryUrl) = "http://www.tag-stage.com/photo_gallery.html";
}
else {
    our ($username)  = 'aeloyan+kafka@tagged.com';
    our ($password)  = "random33";
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

    eval {$mech->get($main::loginUrl)};
    print "FAIL_GET\n" if $@;

    if ($DEBUG_MESSAGES) {
        print "POST_URL....................................OK \n";
    }

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