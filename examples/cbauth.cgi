#!/usr/bin/perl -w

require './CBAuth.pm';
my $app = CBAuth->new();
$app->process();
