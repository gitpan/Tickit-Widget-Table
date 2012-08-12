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
	return if $self->{frame};
	my $win = $self->window->make_float(8,8, $self->window->lines - 16, $self->window->cols - 16);
#	bless $win, 'Tickit::Window';
	my $frame = Tickit::Widget::Frame->new(
		style => 'single',
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
	$vbox->add($content, expand => 0.75);
	my $hbox = Tickit::Widget::HBox->new;
	$hbox->add(Tickit::Widget::Static->new(text => ''), expand => 0.25);
	$hbox->add($buttons, expand => 0.5);
	$hbox->add(Tickit::Widget::Static->new(text => ''), expand => 0.25);
	$vbox->add($hbox, expand => 0.25);
	$frame->add($vbox);
	$frame->set_window($win);
	$self->{frame} = $frame;
	$win->show;
	$win->expose;
	$buttons->refit;
}

=head2 hide

Remove the dialog window.

=cut

sub hide {
	my $self = shift;
	return $self unless my $frame = delete $self->{frame};
	my $win = $frame->window or return $self;
	$win->hide;
	$frame->set_window(undef);
	$frame->remove($_) for $frame->children;
	$self
}

package Tickit::Widget::Menubar::Horizontal;
use base qw(Tickit::Widget::Table);

=head1 DESCRIPTION

Implementation of a horizontal menu, such as the menu bar at the top of the screen.

=cut

=head2 new

=cut

sub new {
	my $class = shift;
	my %args = @_;

	# Instantiate a single-row table in column-select mode
	my $self = $class->SUPER::new(
		%args,
		padding => 1,
		header => 0,
		highlight_mode => 'column',
		columns => [ ],
	);
	$self
}

=head2 add_item

Adds the given item to this menu.

=cut

sub add_item {
	my $self = shift;
	my %args = @_;

	$args{type} //= 'item';
	$self->add_row unless $self->children;
	my $col = $self->add_column(
		label => '',
		align => $args{align} // 'left',
		 ($args{type} eq 'spacer')
		? (width => 'auto', can_highlight => 0)
		: (width => 'min'),
	);
	$col->action($args{action}) if exists $args{action};
	my ($row) = ($self->children)[-1];
	my ($cell) = ($row->children)[-1];
	$cell->set_text($args{label});
	$self
}

=head2 highlight_attrs

Default attributes - show highlighted items in bold

=cut

sub highlight_attrs { +{ fg => 6, b => 1, bg => 4 } }

=head2 normal_attrs

Apply a blue background to the standard menu

=cut

sub normal_attrs { +{ fg => 7, bg => 4, b => 0 } }

package Tickit::Widget::Menubar::Vertical;
use base qw(Tickit::Widget::Table);

=head2 new

Instantiates a new menu using vertical style.

=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $menu = delete $args{menu};

	# Instantiate a single-column table in row-select mode
	my $self = $class->SUPER::new(
		%args,
		padding => 0,
		header => 0,
		highlight_mode => 'row',
		columns => [ { label => ' ', align => 'left', width => 'auto' } ]
	);
	return $self;
}

=head2 add_item

Adds a new item to this menu.

=cut

sub add_item {
	my $self = shift;
	my %args = @_;

	my $row = $self->add_row(
		data => [ $args{label} ],
		 ($args{type} eq 'spacer')
		? (can_highlight => 0)
		: (),
	);
	$row->action($args{action}) if exists $args{action};
	$self
}

sub highlight_attrs { +{ fg => 6, b => 1, bg => 4 } }
sub normal_attrs { +{ fg => 7, bg => 4, b => 0 } }

package Tickit::Widget::Menubar::Item;

=head2 new

Instantiate a new menu item.

Takes the following named parameters:

=over 4

=item * label - what to display as the label, currently text only, may include an accelerator key
using the & prefix for example '&File' would be 'File' with Alt-F as the shortcut

=item * on_activate - optional code to call when the item is activated

=back

=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless +{ }, $class;
	my $label = delete $args{label};
	$self->{$_} = delete $args{$_} for grep exists $args{$_}, qw(on_activate parent_menu);
	if(my ($hotkey) = $label =~ s/&(\w)/$1/) {
		my $key_str = lc $hotkey;
		$key_str = "Alt-$key_str" if $self->parent_menu;
		$self->bind_key($key_str  => sap($self, sub { shift->activate }));
	}
	$self->{label} = $label;
	$self
}

=head2 sap

=cut

sub sap {
	my ($obj, $sub) = @_;
	Scalar::Util::weaken $obj;
	return sub {
		$obj->$sub(@_);
	};
}

=head2 parent_menu

Returns the parent for this menu.

=cut

sub parent_menu { shift->{parent_menu} }

=head2 bind_key

Binds the key combination to the given coderef.

Expects two parameters: the key combination, and the coderef to call when that
combination is pressed.

Examples of key combinations:

 Alt-F
 Alt-f
 x
 Ctrl-X
 Shift-Y
 Ctrl-Alt-Z
 Alt-Ctrl-Insert

=cut

sub bind_key {
	my $self = shift;
	my ($k, $code) = @_;
	warn "$k => $code\n";
	$self
}

=head2 add_item

Adds this item to a parent L<Tickit::Widget::Menubar::Item>.

=cut

sub add_item {
	my $self = shift;
	my $item = shift;
	push @{$self->{children}}, $item;
	unless($self->{menu}) {
		my $menu_class = 'Tickit::Widget::Menubar::' . ($self->parent_menu ? 'Vertical' : 'Horizontal');
		$self->{menu} = $menu_class->new;
	}
	$self->{menu}->add_item(
		label => $item->label,
		action => sap($item, 'activate'),
		type => $item->type,
	);
	$item->set_parent_menu($self);
	push @{$self->{menu_items}}, $item;
	$self
}

sub label { shift->{label} }

=head2 activate

Calls the activation function if one is defined. See the C<on_activate>
parameter to L</new> for setting this.

=cut

sub activate {
	my $self = shift;
	my $menu = shift;
	if(@{$self->{menu_items} || []}) {
		my $item = $menu->highlighted_item;
		if($menu->highlight_mode eq 'column') {
			($item) = ($item->cells)[-1];
		}
		$self->show_menu(
			left => $item->window->left,
			top => $item->window->top,
		);
		return $self;
	}
	$self->{on_activate}->($self) if $self->{on_activate};
	$self
}

=head2 set_parent_menu

Sets the parent for this item. Should be another L<Tickit::Widget::Menubar::Item>
or L<Tickit::Widget::Menubar>.

=cut

sub set_parent_menu {
	my $self = shift;
	my $parent = shift;
	$self->{parent_menu} = $parent;
	$self
}

=head2 menu

Returns the current submenu.

=cut

sub menu { shift->{menu} }

=head2 popup

Returns the floating window used for the menu popup.

=cut

sub popup { shift->parent_menu->popup(@_) }

sub popup_container { shift->parent_menu->popup_container }

=head2 show_menu

Shows the menu. Instantiates a new floating window.

=cut

sub show_menu {
	my $self = shift;
	my %args = @_;
	return if $self->popup;
	my $win = $self->parent_menu->popup_container or die "No popup container window?";
	my $subframe = Tickit::Widget::Frame->new(
		style => 'single',
		$self->menu_attrs
	);
	$subframe->add($self->menu);
	$self->popup(
		$win->make_float(1, 0 + $args{left}, $subframe->lines, $subframe->cols),
		on_remove => sap($self, 'deactivate'),
	);
	$subframe->set_window($self->popup);
	$self->{subframe} = $subframe; # keep a ref
	# Tickit::Window
	$self->popup->show;
	$self->menu->resized;
	$self
}

sub deactivate {
	my $self = shift;
	return $self unless my $frame = delete $self->{subframe};
	my $win = $frame->window or return $self;
	$win->hide;
	$frame->set_window(undef);
	$frame->remove($_) for $frame->children;
	$win->root->expose;
	$self
}

sub type { 'item' }

sub menu_attrs {
	my $self = shift;
	(bg => 4)
}

package Tickit::Widget::Menubar::Item::Separator;
use parent -norequire => qw(Tickit::Widget::Menubar::Item);

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless +{
		label => '',
	}, $class;
	$self->{$_} = delete $args{$_} for grep exists $args{$_}, qw(parent_menu);
	$self
}

sub type { 'spacer' }

package Tickit::Widget::Menubar;
use parent -norequire => qw(Tickit::Widget::Menubar::Horizontal);

=head1 DESCRIPTION

Implements the logic to wrap the horizontal and vertical menus comprising a typical
Menubar layout.

=cut

sub sap {
	my ($obj, $sub) = @_;
	Scalar::Util::weaken $obj;
	return sub {
		$obj->$sub(@_);
	};
}

sub deactivate_item {
	my $self = shift;

}

sub on_key {
	my $self = shift;
	my ($type, $str, $key) = @_;
	# If we're showing a popup menu already, we might want to move to the next one
	if($self->popup && $type eq 'key' && ($str eq 'Left' || $str eq 'Right')) {
		if(my $code = delete $self->{popup_removal}) {;
			$code->() 
		}
		$self->popup->hide;
		delete $self->{popup};
		$self->SUPER::on_key(@_);
#		$self->highlighted_item->activate;
		return 1;
	}
	return $self->SUPER::on_key(@_);
}

sub new {
	my $class = shift;
	my %args = @_;
	my $popup_container = delete $args{popup_container} or die "no popup container";
	my $self = $class->SUPER::new(%args);
	$self->{popup_container} = $popup_container;
	$self
}

sub popup_container {shift->{popup_container} }

sub popup {
	my $self = shift;
	if(@_) {
		$self->{popup} = shift;
		my %args = @_;
		$self->{popup_removal} = delete $args{on_remove};
		warn "Unknown args: " . join ',', keys %args if %args;
		return $self;
	}
	return $self->{popup};
}

sub add_item {
	my $self = shift;
	my $item = shift;
	$self->SUPER::add_item(
		label => $item->label,
		action => sap($item, 'activate'),
		type => $item->type,
	);
	$item->set_parent_menu($self);
	push @{$self->{menu_items}}, $item;
	$self
}

=pod

	$menu->on_highlight_changed(
		sub {
			my $menu = shift;
			if($self->popup) {
				warn "Should change popup to " . $menu->highlighted_item;
			}
		}
	);
	$menu->bind_key(
		sub {
			my ($type, $str, $key) = @_;
			if($type eq 'key') {
				if($str eq 'Escape') {
					warn "Had escape";
					return 0 unless $self->popup;
					$self->popup->hide;
					delete $self->{popup};
					$menu->redraw;
					return 0;
				}
			}
			return 1;
		}
	);
	$menu;
}

=cut

package Layout;
use parent qw(Tickit::Async);

use Tickit::Widget::VBox;
use Tickit::Widget::Entry;
use Tickit::Widget::Static;
use Tickit::Widget::HBox;
use Tickit::Widget::Frame;
use Tickit::Widget::Scroller;
use Tickit::Widget::Scroller::Item::Text;
use Tickit::Widget::Statusbar;

sub on_open {
	my $self = shift;
	warn "Open...";
}

sub on_save {
	my $self = shift;
	warn "Save...";
}

sub on_save_as {
	my $self = shift;
	warn "Save as...";
}

sub on_exit {
	my $self = shift;
	warn "Exit...";
	$::LOOP->later(sub { $::LOOP->loop_stop });
}

sub on_copy {
	my $self = shift;
	warn "Copy...";
}

sub on_cut {
	my $self = shift;
	warn "Cut...";
}

sub on_paste {
	my $self = shift;
	warn "Paste...";
}

sub on_help_about {
	my $self = shift;
	warn "About...";
	return if $self->{dialog};
	my $dialog; $dialog = Tickit::Widget::Dialog->new(
		window => $self->rootwin,
		title => 'A modal dialog box',
		content => 'This is the descriptive text that would appear',
		button => [
			'OK' => sub { warn "OK pressed"; $dialog->hide },
			'Cancel' => sub { warn "Cancel pressed"; $dialog->hide },
		]
	);
	$dialog->show;
	$self->{dialog} = $dialog;
	$self
}

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->{current_line} = 0;

# Top-level holder

	my $out;
	my $messages = Tickit::Widget::VBox->new;
	my $report = sub {
		my $msg = join ' ', map s/\n+//rg, @_;
		if($messages->window) {
			$messages->remove(0) while $messages->children >= $messages->window->lines;
		}
		$messages->add(Tickit::Widget::Static->new(text => $msg, align => 'left', valign => 'top'));
	};
	$SIG{__WARN__} = $report;

	my $holder = Tickit::Widget::VBox->new;
	$self->{holder} = $holder;
	my $mb = $self->{menubar} = Tickit::Widget::Menubar->new(
		popup_container => $self->rootwin,
	);
	my $app = $self;
	$mb->add_item(my $item = Tickit::Widget::Menubar::Item->new(label => '&File'));
	$item->add_item(Tickit::Widget::Menubar::Item->new(
		label => '&Open',
		on_activate => sub { shift; $app->on_open(@_) }
	));
	$item->add_item(Tickit::Widget::Menubar::Item->new(
		label => '&Save',
		on_activate => sub { shift; $app->on_save(@_) }
	));
	$item->add_item(Tickit::Widget::Menubar::Item->new(
		label => 'Save &as...',
		on_activate => sub { shift; $app->on_save_as(@_) }
	));
	$item->add_item(Tickit::Widget::Menubar::Item::Separator->new);
	$item->add_item(Tickit::Widget::Menubar::Item->new(label => 'E&xit', on_activate => sub { shift; $app->on_exit(@_) }));
	$mb->add_item($item = Tickit::Widget::Menubar::Item->new(label => 'E&dit'));
	$item->add_item(Tickit::Widget::Menubar::Item->new(label => 'C&ut', on_activate => sub { shift; $app->on_cut(@_) }));
	$item->add_item(Tickit::Widget::Menubar::Item->new(label => '&Copy', on_activate => sub { shift; $app->on_copy(@_) }));
	$item->add_item(Tickit::Widget::Menubar::Item->new(label => '&Paste', on_activate => sub { shift; $app->on_paste(@_) }));
	$mb->add_item(Tickit::Widget::Menubar::Item::Separator->new);
	$mb->add_item($item = Tickit::Widget::Menubar::Item->new(label => '&Help'));
	$item->add_item(Tickit::Widget::Menubar::Item->new(label => '&About', on_activate => sub { shift; $app->on_help_about(@_) }));

	$holder->add($mb);
	my $panes = Tickit::Widget::HBox->new;
	my $left = Tickit::Widget::Static->new(text => 'left pane');
	my $right = Tickit::Widget::Static->new(text => 'right pane');
	my $frame = Tickit::Widget::Frame->new(
		style => 'double'
	);
	$frame->add($left);
	$panes->add($frame, expand => 1);
	$frame = Tickit::Widget::Frame->new(
		style => 'single'
	);
	$frame->add($right);
	$panes->add($frame, expand => 1);
	$holder->add($panes, expand => 1);
	$holder->add($messages, expand => 0.1);
	$holder->add(Tickit::Widget::Statusbar->new(loop => $::LOOP));
	$holder->set_window($self->rootwin);
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
	# hax
	$::LOOP = $self->{loop};
	$self->{ui} = Layout->new;
	$self->loop->add($self->ui);
	$self->ui->run;
}

sub loop { shift->{loop} }
sub ui { shift->{ui} }

package main;

our $LOOP;
MenuLayout->new->run;

