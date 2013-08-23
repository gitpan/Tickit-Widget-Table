#!/usr/bin/env perl 
use strict;
use warnings;
use Tickit;
use Tickit::Widget::Table;
use Tickit::Widget::ScrollBox;

my $tickit = Tickit->new;
my $scroll = Tickit::Widget::ScrollBox->new(
	vertical => 1,
	horizontal => 0,
	child => my $tbl = Tickit::Widget::Table->new(
		padding => 1,
		columns => [
			{ label => 'Left column', align => 'left', width => 'auto' },
			{ label => 'Middle column', align => 'centre', width => 'auto' },
			{ label => 'Right column', align => 'right', width => 'auto' },
		],
	)
);
$tbl->add_row(data => [
	"Row $_",
	int(100 * rand),
	"Longer text would be here",
]) for 1..50;
$tickit->set_root_widget($scroll);
$tickit->run;

