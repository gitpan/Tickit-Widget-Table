#!/usr/bin/perl 
use strict;
use warnings;
package Tickit::Widget::Dialog;
use Tickit::Widget::Static;
use Tickit::Widget::Frame;
use Tickit::Widget::Table;

sub new {
	my $class = shift;
	my $self = bless { @_ }, $class;
	$self
}

sub window { shift->{window} }
sub title { shift->{title} }
sub content { shift->{content} }

sub show {
	my $self = shift;
	my $win = $self->window->make_float(8,8, $self->window->lines - 16, $self->window->cols - 16);
	my $frame = Tickit::Widget::Frame->new(
		style => { linestyle => 'single' },
		title => $self->title,
		title_align => 0.5,
	);
	my $vbox = Tickit::Widget::VBox->new;
	my $content = ref $self->content ? $self->content : Tickit::Widget::Static->new(
		text => $self->content,
		align => 'centre',
		valign => 'middle',
	);
	my $buttons = Tickit::Widget::Table->new(
		padding => 0,
		header => 0,
		highlight_mode => 'column',
		columns => [],
	);
	my @items = @{ $self->{button} };
	my @label;
	while(@items) {
		my ($label, $code) = splice @items, 0, 2;
		push @label, $label;
		my $col = $buttons->add_column(
			label => '',
			align => 'center',
			width => 'auto',
		);
		$col->action($code);
	}
	$buttons->add_row(data => \@label);
	$vbox->add($content, expand => 3);
	my $hbox = Tickit::Widget::HBox->new;
	$hbox->add(Tickit::Widget::Static->new, expand => 1);
	$hbox->add($buttons, expand => 2);
	$hbox->add(Tickit::Widget::Static->new, expand => 1);
	$vbox->add($hbox, expand => 1);
	$frame->add($vbox);
	$frame->set_window($win);
	$self->{frame} = $frame;
	$win->show;
}

package Layout;
use parent qw(Tickit::Async);

use Tickit::Widget::Scroller;
use Tickit::Widget::Scroller::Item::Text;
use Tickit::Widget::VBox;
use Tickit::Widget::Entry;
use Tickit::Widget::Static;
use Tickit::Widget::HBox;
#Tickit::ContainerWidget;
use Tickit::Widget::Frame;

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->{current_line} = 0;

# Top-level holder

	my $out;
	my $messages;
	my $report = sub {
		my $msg = shift;
		$messages->remove(0) while $messages->children >= $self->rootwin->lines;
		$messages->add(Tickit::Widget::Static->new(text => $msg, align => 'left', valign => 'top'));
	};

	$messages = Tickit::Widget::VBox->new;
	my $holder = Tickit::Widget::VBox->new;
	$holder->set_window($self->rootwin);
	$self->{holder} = $holder;
	$self->{dialog} = Tickit::Widget::Dialog->new(
		window => $self->rootwin,
		title => 'A modal dialog box',
		content => 'This is the descriptive text that would appear',
		button => [
			'OK' => sub { warn "OK pressed" },
			'Cancel' => sub { warn "Cancel pressed" },
		]
	);
	$self->{dialog}->show;
	$holder->add(my $s = Tickit::Widget::Scroller->new, expand => 1);
	$s->push(map Tickit::Widget::Scroller::Item::Text->new("<Line $_ on the background window>"), 1..50);
#	$holder->add($messages, expand => 1);
	$self->rootwin->expose;
	return $self;
}

package MenuLayout;
use utf8;
use IO::Async::Loop;

sub new { bless { }, shift }

sub run {
	my $self = shift;
	$self->{loop} = IO::Async::Loop->new;
	$self->{ui} = Layout->new;
	# hax
	$::LOOP = $self->{loop};
#	$self->loop->add($self->ui);
	$self->ui->run;
}

sub loop { shift->{loop} }
sub ui { shift->{ui} }

package main;
MenuLayout->new->run;

__END__

$mb->add(my $item = Tickit::Widget::MenuBar::Item->new(text => 'File'));
$item->add(Tickit::Widget::MenuBar::Item->new(text => 'Open', on_activate => sub { shift; $app->on_open(@_) }));
$item->add(Tickit::Widget::MenuBar::Item->new(text => 'Save', on_activate => sub { shift; $app->on_save(@_) }));
$item->add(Tickit::Widget::MenuBar::Item->new(text => 'Save As...', on_activate => sub { shift; $app->on_save_as(@_) }));
$item->add(Tickit::Widget::MenuBar::Item::Separator->new;
$item->add(Tickit::Widget::MenuBar::Item->new(text => 'Exit', on_activate => sub { shift; $app->on_exit(@_) }));
$mb->add($item = Tickit::Widget::MenuBar::Item->new(text => 'Edit'));
$item->add(Tickit::Widget::MenuBar::Item->new(text => 'Cut', on_activate => sub { shift; $app->on_cut(@_) }));
$item->add(Tickit::Widget::MenuBar::Item->new(text => 'Copy', on_activate => sub { shift; $app->on_copy(@_) }));
$item->add(Tickit::Widget::MenuBar::Item->new(text => 'Paste', on_activate => sub { shift; $app->on_paste(@_) }));
$mb->add($item = Tickit::Widget::MenuBar::Item->new(text => 'Help'));
$item->add(Tickit::Widget::MenuBar::Item->new(text => 'About', on_activate => sub { shift; $app->on_help_about(@_) }));

