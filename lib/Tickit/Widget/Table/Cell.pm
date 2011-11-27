package Tickit::Widget::Table::Cell;
{
  $Tickit::Widget::Table::Cell::VERSION = '0.001';
}
use strict;
use warnings;
use 5.010;
use parent qw(Tickit::Widget::Static);

=head1 NAME

Tickit::Widget::Table::Cell - cells in a L<Tickit::Widget::Table>.

=head1 VERSION

version 0.001

=head1 SYNOPSIS

see L<Tickit::Widget::Table>.

=head1 DESCRIPTION

Not intended for direct use - see L<Tickit::Widget::Table>.

=cut

use Scalar::Util qw(weaken);

=head1 METHODS

=cut

=head2 cols

Delegates to the L<Tickit::Widget::Column> which should have a better idea of the total columns for this cell.

=cut

sub cols {
	my $self = shift;
	return 1 unless $self->column;
	return $self->column->cols;
}

=head2 display_xpos

Left position to start writing text at.

=cut

sub display_xpos {
	my $self = shift;
	my $win = $self->window or return;
	my $txt = $self->display_value;
	my $x = 0;

	my $padding = $self->column->idx ? $self->table->padding : 0;
	given($self->column->align) {
	when('left') { $x = $padding; }
	when('right') { $x = ($win->cols - 1) - (length($txt)); }
	when('center') { $x = $padding + (($win->cols - 1) - (length($txt))) / 2; }
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

=head2 render

Either render through the parent class or delegate to our widget.

=cut

sub render {
	my $self = shift;
	my $win = $self->window or return;
	if($self->{widget}) {
		$self->{widget}->render(@_);
	} else {
		# Tickit::Widget::Static probably
		$self->SUPER::render(@_);
	}
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

sub column { shift->{column} }
sub row { shift->{row} }
sub table { shift->{table} }

sub new {
	my $class = shift;
	my %args = @_;
	my $table = delete $args{table};
	my $row = delete $args{row} or die "No row";
	my $col = delete $args{column} or die "No column";
	my $content = delete $args{content};
	my $self = $class->SUPER::new(%args);
	$self->set_column($col);
	$self->set_row($row);
	$self->set_table($table);

	$col->add_cell($self);
	if(ref $content) {
		$self->{widget} = $content;
	} else {
		$self->set_text($content);
	}
	return $self;
}

sub set_table {
	my $self = shift;
	$self->{table} = shift;
	weaken $self->{table};
	return $self;
}
sub set_column {
	my $self = shift;
	$self->{column} = shift;
	weaken $self->{column};
	return $self;
}

sub set_row {
	my $self = shift;
	$self->{row} = shift;
	weaken $self->{row} if ref $self->{row};
	return $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
