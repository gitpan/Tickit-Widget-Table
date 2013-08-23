package Tickit::Widget::Table::Cell;
{
  $Tickit::Widget::Table::Cell::VERSION = '0.100';
}
use strict;
use warnings;
use 5.010;
use parent qw(Tickit::Widget::Static Tickit::Widget::Table::Highlight);

=head1 NAME

Tickit::Widget::Table::Cell - cells in a L<Tickit::Widget::Table>.

=head1 VERSION

version 0.100

=head1 DESCRIPTION

Not intended for direct use - see L<Tickit::Widget::Table>.

=cut

use Tickit::Utils qw(textwidth);
use Scalar::Util qw(weaken);

use Tickit::Style;

BEGIN {
	style_definition base =>
		fg => 'white',
		spacing => 0;

	style_definition ':highlight' =>
		fg => 'yellow',
		bg => 'blue',
		b => 1;
}

use constant CLEAR_BEFORE_RENDER => 0;
use constant WIDGET_PEN_FROM_STYLE => 1;

=head1 METHODS

=cut

=head2 cols

Delegates to the L<Tickit::Widget::Column> which should have a better idea of the total columns for this cell.

=cut

sub cols {
	my $self = shift;
	if(defined(my $displayed = $self->column->displayed_width)) {
		return $displayed;
	}
	return $self->{widget} ? $self->{widget}->cols : $self->SUPER::cols;
}

sub rows { 1 }

=head2 display_xpos

Left position to start writing text at.

=cut

sub display_xpos {
	my $self = shift;
	my $win = $self->window or return;
	my $txt = $self->display_value;
	my $x = 0;

	my $padding = $self->column->idx ? $self->table->padding : 0;
	for($self->column->align) {
	when('left') { $x = $padding; }
	when('right') { $x = ($win->cols - 1) - (textwidth $txt); }
	when('center') { $x = $padding + (($win->cols - 1) - (textwidth $txt)) / 2; }
	when(undef) { die "Undef value found for alignment"; }
	default { die "what kind of alignment do you think $_ is?"; }
	}
	$x = 0 if $x < 0;
	return $x;
}

=head2 window_gained

Pass our window on to the child widget if we have one.

=cut

sub window_gained {
	my $self = shift;
	$self->SUPER::window_gained(@_);
	return unless $self->{widget};

	my $win = $self->window or return;

# Pass through the new window info to the widget
	my $child_win = $win->make_sub(0,0,$win->lines,$win->cols);
	$self->{widget}->set_window($child_win);
	$self->{widget}->redraw;
}

=head2 window_lost

Remove the child widget window.

=cut

sub window_lost {
	my $self = shift;
	$self->SUPER::window_lost(@_);
	return unless $self->{widget};

# Clear window from widget
	$self->{widget}->set_window(undef);
}

=head2 render_to_rb

Either render through the parent class or delegate to our widget.

=cut

sub render_to_rb {
	my ($self, $rb, $rect) = @_;

	if($self->{widget}) {
		$self->{widget}->render_to_rb(@_);
	} else {
		my $txt = $self->text;
		$rb->goto(0,0);
		my $padding = $self->table->padding;

		my $pen = $self->get_style_pen;
#		warn "Spaces: " . (-$padding + $self->cols - textwidth $txt);
		$rb->text($txt . (' ' x (-$padding + $self->cols - textwidth $txt)), $pen);
		# Tickit::Widget
		$rb->erase($padding, $pen) if $padding;
	}
}

sub update_highlight_style {
	my $self = shift;
	$self->set_style_tag(highlight => shift);
	$self
}

=head2 display_value

Value to use when displaying this cell. Probably the text content.

=cut

sub display_value {
	my $self = shift;
	return $self->{display_value} if exists $self->{display_value};
	my $v = $self->{data};
	$v = $self->column->apply_format($v) if $self->column->format;
	$v //= 'undef';
	$self->{display_value} = $v;
	return $v;
}

=head2 display_width

Returns the number of columns our current value will require.

=cut

sub display_width {
	my $self = shift;
	textwidth $self->display_value;
}

=head2 column

Accessor for the L<Tickit::Widget::Table::Column> this cell resides in.

=cut

sub column { shift->{column} }

=head2 row

Accessor for the L<Tickit::Widget::Table::Row> this cell resides in.

=cut

sub row { shift->{row} }

=head2 table

Accessor for the L<Tickit::Widget::Table> this cell resides in.

=cut

sub table { shift->{table} }

=head2 new

Instantiate a new cell.

Takes the following named parameters:

=over 4

=item * table - the L<Tickit::Widget::Table> which will hold this cell

=item * row - the L<Tickit::Widget::Row> which will hold this cell

=item * column - the L<Tickit::Widget::Column> which will hold this cell

=item * content (optional) - content, either a string or a L<Tickit::Widget> subclass

=back

Returns the new cell.

=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $table = delete $args{table};
	my $row = delete $args{row} or die "No row";
	my $col = delete $args{column} or die "No column";
	my $content = delete $args{content};
	my $self = $class->SUPER::new(%args, text => '');
	$self->{highlighted} = 0;
	$self->set_column($col);
	$self->set_row($row);
	$self->set_table($table);

	$col->add_cell($self);
	$content = '' unless defined $content;
	if(ref $content) {
		$self->{widget} = $content;
	} else {
		$self->set_text($content);
	}
	return $self;
}

=head2 set_table

Change the L<Tickit::Widget::Table> for this cell.

Returns $self.

=cut

sub set_table {
	my $self = shift;
	$self->{table} = shift;
	weaken $self->{table};
	return $self;
}

=head2 set_column

Change the L<Tickit::Widget::Table::Column> for this cell.

Returns $self.

=cut

sub set_column {
	my $self = shift;
	$self->{column} = shift;
	weaken $self->{column};
	return $self;
}

=head2 set_row

Change the L<Tickit::Widget::Table::Row> for this cell.

Returns $self.

=cut

sub set_row {
	my $self = shift;
	$self->{row} = shift;
	weaken $self->{row} if ref $self->{row};
	return $self;
}

=head2 action

Accessor/mutator for the action that should be performed when this
cell is activated. This would be by way of being a coderef.

=cut

sub action {
	my $self = shift;
	if(@_) {
		$self->{action} = shift;
		return $self;
	}
	return $self->{action};
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
