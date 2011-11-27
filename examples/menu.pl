#!/usr/bin/perl 
use strict;
use warnings;
package Tickit::Widget::Menu;
use base qw(Tickit::Widget::Table);

=head2 new

=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $menu = delete $args{menu};
	my $self = $class->SUPER::new(
		%args,
		padding => 0,
		header => 0,
		columns => [ { label => ' ', align => 'center', width => 'auto' } ]
	);
	while(@$menu) {
		my ($label, $code) = splice @$menu, 0, 2;
		my $row = $self->add_row($label);
		$row->action($code);
	}
	return $self;
}

package Layout;
use parent qw(Tickit::Async);

use Tickit::Widget::VBox;
use Tickit::Widget::Entry;
use Tickit::Widget::Static;
use Tickit::Widget::HBox;
#Tickit::ContainerWidget;

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
	my $holder = Tickit::Widget::HBox->new;
	$holder->set_window($self->rootwin);
	$self->{holder} = $holder;
	my $menu = Tickit::Widget::Menu->new(
		menu => [
			'New' => sub { $report->( "Selected 'new'"); },
			'Open' => sub { $report->( "Selected 'open'"); },
			'Save' => sub { $report->( "Selected 'save'"); },
			'Exit' => sub {
				$report->( "Selected 'exit'");
				my $loop = $self->get_loop;
				$loop->later(sub {
					$loop->loop_stop;
				});
			},
		]
	);
	$holder->add($menu);
	$holder->add($messages, expand => 1);
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
	$self->loop->add($self->ui);
	$self->ui->run;
}

sub loop { shift->{loop} }
sub ui { shift->{ui} }

package main;
MenuLayout->new->run;

