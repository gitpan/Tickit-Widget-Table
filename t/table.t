#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use Test::More skip_all =>'pending';
use Test::Deep;
use Tickit::Test;

use Tickit::Widget::Table;

binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

my ($term, $win) = mk_term_and_window;

my $widget = new_ok('Tickit::Widget::Table' => [
	padding => 1,
	header  => 1,
	columns => [
		{ label => 'header', align => 'center', width => 'auto' }
	]
]);

#cmp_deeply([ $widget->data ],  [ 0, 1, 2, 3, 4], 'data is correct');
is($widget->lines, 1, '$widget->lines' );
$widget->set_window( $win );

flush_tickit();

note explain $term->methodlog;

is_termlog([
	SETPEN,
	CLEAR,
	GOTO(0,0),
	SETPEN,
	PRINT(" " x 16),
	GOTO(0,16),
	SETPEN,
	PRINT("\x{2581}" x 16),
	GOTO(0,32),
	SETPEN,
	PRINT("\x{2583}" x 16),
	GOTO(0,48),
	SETPEN,
	PRINT("\x{2585}" x 16),
	GOTO(0,64),
	SETPEN,
	PRINT("\x{2588}" x 16),
	# Check that we clear the rest of the area
	map {
		GOTO($_,0),
		SETBG(undef),
		ERASECH(80),
	} 1..24
], 'full width graph has correct chars');

$widget->pen->chattr( fg => 2 );

flush_tickit();
is_termlog([
	SETPEN(fg => 2),
	CLEAR,
	GOTO(0,0),
	SETPEN(fg => 2),
	PRINT(" " x 16),
	GOTO(0,16),
	SETPEN(fg => 2),
	PRINT("\x{2581}" x 16),
	GOTO(0,32),
	SETPEN(fg => 2),
	PRINT("\x{2583}" x 16),
	GOTO(0,48),
	SETPEN(fg => 2),
	PRINT("\x{2585}" x 16),
	GOTO(0,64),
	SETPEN(fg => 2),
	PRINT("\x{2588}" x 16),
	# Check that we clear the rest of the area
	map {
		GOTO($_,0),
		SETBG(undef),
		ERASECH(80),
	} 1..24
], 'redraw after changing pen');

