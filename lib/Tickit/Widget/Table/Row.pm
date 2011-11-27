package Tickit::Widget::Table::Row;
{
  $Tickit::Widget::Table::Row::VERSION = '0.002';
}
use strict;
use warnings;
use parent qw(Tickit::Widget::HBox);

=head1 NAME



=head1 SYNOPSIS

=head1 VERSION

version 0.002

=head1 DESCRIPTION

=cut

use Scalar::Util qw(weaken);
use Tickit::Widget::Table::Cell;

=head1 METHODS

=cut

sub lines { 1 }
sub cols { 1 }

=head2 new

=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $table = delete $args{table};
	my $column = delete $args{column};
	my $data = delete $args{data} || [];
	my $self = $class->SUPER::new(%args);
	$self->{table} = $table;

	my $cell_class = $self->cell_type;
	foreach my $col (@$column) {
		my $cell = $cell_class->new(
			table	=> $self->{table},
			row	=> $self,
			column	=> $col,
			content	=> shift(@$data),
		);
		$self->add($cell);
	}
	return $self;
}

sub remove {
	my $self = shift;
	my $idx = 0;
	$self->SUPER::remove($_) for $self->children;
}

sub table { shift->{table} }
sub is_highlighted { shift->{highlighted} ? 1 : 0 }
sub is_selected { shift->{selected} ? 1 : 0 }

=head2 selected

Get or set the selection status for this row.

=cut

sub selected {
	my $self = shift;
	if(@_) {
		my $v = shift;
		unless($v ~~ $self->{selected}) {
			$self->{selected} = $v;
			$self->resized;
		}
		return $self;
	}
	return $self->{selected};
}

sub highlighted {
	my $self = shift;
	if(@_) {
		my $v = shift;
		if($v ~~ $self->{highlighted}) {
			$self->{highlighted} = $v;
		} else {
			$self->{highlighted} = $v;
#			$self->resized;
			$self->pen->chattr( bg => $self->is_highlighted ? 4 : 0 );
#			$_->update_pen for $self->children;
		}
		return $self;
	}
	return $self->{highlighted};
}

=head2 cell_type

Default expected cell type for entries in this row.

Typically either L<Tickit::Widget::Table::Cell> or
L<Tickit::Widget::Table::HeaderCell>.

=cut

sub cell_type { 'Tickit::Widget::Table::Cell' }

=head2 add_column

Add a new column to the end of the row.

=cut

sub add_column {
	my $self = shift;
	my $col = shift;
	my $cell_class = $self->cell_type;
	my $cell = $cell_class->new(
		table	=> $self->{table},
		row	=> $self,
		column	=> $col
	);
	$self->add($cell);
	return $self;
}

=head2 cell

Returns the cell at the given index.

=cut

sub cell {
	my $self = shift;
	my $idx = shift;
	return ($self->children)[$idx];
}

=head2 reposition_cursor

Move cursor to home position.

=cut

sub reposition_cursor {
	my $self = shift;
	my $win = $self->window or return;
	$win->focus(0, 0);
}

sub action {
	my $self = shift;
	if(@_) {
		$self->{action} = shift;
		return $self;
	}
	return $self->{action};
}

sub xrender {
	my $self = shift;
	$self->SUPER::render(@_);
	my $win = $self->window or return;
	foreach my $line ($win->lines - 1) {
		$win->goto($line, 0);
		$win->print(' ' x $win->cols, bg => $self->is_highlighted ? 4 : 0);
	}
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
