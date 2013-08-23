#!/usr/bin/env perl 
use strict;
use warnings;
use Tickit;
use Tickit::Widget::Table;
use Tickit::Style;

Tickit::Style->load_style(<<'EOF');
Table::HeaderCell.left {
  fg: "blue";
  bg: "black";
  b: 1;
}

Table::Cell.left {
  fg: "green";
  b: 1;
}

Table::Cell.left:highlight {
  fg: "white";
  bg: "red";
  b: 1;
}

Table::HeaderCell.right {
  fg: "red";
  bg: "black";
  b: 1;
}

Table::Cell.right {
  fg: "yellow";
  bg: "black";
  b: 0;
}

Table::Cell.right:highlight {
  fg: "green";
  bg: "black";
  b: 1;
}
EOF

my $tickit = Tickit->new;
my $vbox = Tickit::Widget::VBox->new;
my $left = Tickit::Widget::Table->new(
	class => 'left',
	padding => 1,
	columns => [
		{ label => 'Left column', align => 'left', width => 'auto' },
		{ label => 'Middle column', align => 'centre', width => 'auto' },
		{ label => 'Right column', align => 'right', width => 'auto' },
	],
);
my $right = Tickit::Widget::Table->new(
	class => 'right',
	padding => 1,
	columns => [
		{ label => 'Single column', align => 'left', width => 'auto' },
	],
);
$vbox->add($left, expand => 1);
$vbox->add($right, expand => 1);
# $left->focus(0,0);

$left->add_row(data => [
	"Row $_",
	int(100 * rand),
	"Third column",
]) for 1..5;

$right->add_row(data => [
	"Right row $_",
]) for 1..6;

$tickit->set_root_widget($vbox);
$tickit->run;

