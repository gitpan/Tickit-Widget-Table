#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 43;

use Tickit::Test;
use Tickit::Widget::Table;

binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';
my ( $term, $win ) = mk_term_and_window;

my $tbl = new_ok('Tickit::Widget::Table' => [
	padding => 1,
	columns => [
		{ label => 'Left column', align => 'left', width => 'auto' },
		{ label => 'Middle column', align => 'centre', width => 'auto' },
		{ label => 'Right column', align => 'right', width => 'auto' },
	],
]);
$tbl->add_row(data => [
	"Row $_",
	25.15,
	"Longer text would be here",
]) for 1..3;
ok(!$_->window, 'no window for row before ->set_window') for $tbl->children;
$tbl->set_window($win);
ok($tbl->window, 'table has window after ->set_window');
ok($_->window, 'row has window after ->set_window') for $tbl->children;
for my $cell (map $_->children, $tbl->data_rows) {
	ok($cell->window, 'cell has window after ->set_window');
	isa_ok($cell, 'Tickit::Widget::Table::Cell');
	ok(!$cell->isa('Tickit::Widget::Table::HeaderCell'), 'is not a header cell');
}
for my $header_cell ($tbl->header_row->children) {
	ok($header_cell->window, 'header cell has window after ->set_window');
	isa_ok($header_cell, 'Tickit::Widget::Table::HeaderCell');
}

flush_tickit;
note explain [ $term->methodlog ];
#is_termlog([
#	GOTO(4,0),
#	SETPEN(fg => 7, bg => 4, b => 1),
#	PRINT("Left column              "),
#	SETPEN(fg => 7, bg => 4, b => 1),
#	ERASECH(1, 0),
#	GOTO(0,26),
#	SETPEN(fg => 7, bg => 4, b => 1),
#	PRINT("Middle column            "),
#	SETPEN(fg => 7, bg => 4, b => 1),
#	ERASECH(1, 0),
#	GOTO(0,52),
#	SETPEN(fg => 7, bg => 4, b => 1),
#	PRINT("Right column             "),
#	SETPEN(fg => 7, bg => 4, b => 1),
#	ERASECH(1, 0),
#	GOTO(1,0),
#	SETPEN(fg => 6, bg => 4, b => 1),
#	PRINT("Row 1"),
#	SETPEN(fg => 6, bg => 4, b => 1),
#	ERASECH(21, 0),
#	GOTO(1, 26),
#	SETPEN(fg => 6, bg => 4, b => 1),
#	PRINT("25.15"),
#	SETPEN(fg => 6, bg => 4, b => 1),
#	ERASECH(21, 0),
#	GOTO(1, 52),
#	SETPEN(fg => 6, bg => 4, b => 1),
#	PRINT("Longer text would be here"),
#	SETPEN(fg => 6, bg => 4, b => 1),
#	ERASECH(1, 0),
#	map +(
#		GOTO($_,0),
#		SETPEN(fg => 7, bg => 0),
#		PRINT("Row $_"),
#		SETPEN(fg => 7, bg => 0),
#		ERASECH(21, 0),
#		GOTO($_, 26),
#		SETPEN(fg => 7, bg => 0),
#		PRINT("25.15"),
#		SETPEN(fg => 7, bg => 0),
#		ERASECH(21, 0),
#		GOTO($_, 52),
#		SETPEN(fg => 7, bg => 0),
#		PRINT("Longer text would be here"),
#		SETPEN(fg => 7, bg => 0),
#		ERASECH(1, 0),
#	), 2..3,
#], 'initial table display') or note explain [ $term->methodlog ];

#is_display([
#	[
#		TEXT("Left column              ", fg => 7, bg => 4, b => 1),
#		TEXT(" ", bg => 4),
#		TEXT("Middle column            ", fg => 7, bg => 4, b => 1),
#		TEXT(" ", bg => 4),
#		TEXT("Right column             ", fg => 7, bg => 4, b => 1),
#		TEXT(" ", bg => 4),
#	], [
#		TEXT("Row 1                    ", fg => 6, bg => 4, b => 1),
#		TEXT(" ", bg => 4),
#		TEXT("25.15                    ", fg => 6, bg => 4, b => 1),
#		TEXT(" ", bg => 4),
#		TEXT("Longer text would be here", fg => 6, bg => 4, b => 1),
#		TEXT(" ", bg => 4),
#	], [
#		TEXT("Row 2                    ", fg => 7, bg => 0),
#		TEXT(" ", bg => 0),
#		TEXT("25.15                    ", fg => 7, bg => 0),
#		TEXT(" ", bg => 0),
#		TEXT("Longer text would be here", fg => 7, bg => 0),
#		TEXT(" ", bg => 0),
#	], [
#		TEXT("Row 3                    ", fg => 7, bg => 0),
#		TEXT(" ", bg => 0),
#		TEXT("25.15                    ", fg => 7, bg => 0),
#		TEXT(" ", bg => 0),
#		TEXT("Longer text would be here", fg => 7, bg => 0),
#		TEXT(" ", bg => 0),
#	]
#], 'Display initially');
done_testing;

