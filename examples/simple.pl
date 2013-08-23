#!/usr/bin/env perl 
use strict;
use warnings;
use Tickit;
use Tickit::Widget::Table;

my $tickit = Tickit->new;
my $tbl = Tickit::Widget::Table->new(
	padding => 1,
	columns => [
		{ label => 'Left column', align => 'left', width => 'auto' },
		{ label => 'Middle column', align => 'centre', width => 'auto' },
		{ label => 'Right column', align => 'right', width => 'auto' },
	],
);
$tbl->add_row(data => [
	"Row $_",
	int(100 * rand),
	"Longer text would be here",
]) for 1..20;
$tickit->set_root_widget($tbl);
$tickit->run;

