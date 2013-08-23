package Tickit::Widget::Table::Row;
{
  $Tickit::Widget::Table::Row::VERSION = '0.100';
}
use strict;
use warnings;
use parent qw(Tickit::Widget::HBox Tickit::Widget::Table::Highlight);

=head1 NAME

Tickit::Widget::Table::Row - implementation of a table row

=head1 VERSION

version 0.100

=head1 DESCRIPTION

Implements a row. Nothing particularly exciting here, see method
documentation and L<Tickit::Widget::Table/DESCRIPTION>.

=cut

use Scalar::Util qw(weaken);
use Tickit::Widget::Table::Cell;

use Tickit::Style;

BEGIN {
	style_definition base =>
		spacing => 0;
}

use constant CLEAR_BEFORE_RENDER => 0;
use constant WIDGET_PEN_FROM_STYLE => 1;

=head1 METHODS

=cut

sub lines { 1 }
sub cols { 1 }

=head2 new

Takes the following named parameters:

=over 4

=item * table - L<Tickit::Widget::Table>

=item * column - column definitions

=item * data - data to populate the row with

=back

=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $table = delete $args{table};
	my $column = delete $args{column};
	my $data = delete $args{data} || [];
	my $can_highlight = delete $args{can_highlight} // 1;
	my $self = $class->SUPER::new(%args);
	$self->{highlighted} = 0;
	$self->{table} = $table;
	$self->{can_highlight} = $can_highlight;

	my $cell_class = $self->cell_type;
	foreach my $col (@$column) {
		my $cell = $cell_class->new(
			classes => [ $self->style_classes ],
			table	=> $self->{table},
			row     => $self,
			column	=> $col,
			content	=> shift(@$data),
		);
		$self->add($cell);
	}
	return $self;
}

=head2 remove

Remove this row and all the cells within it.

Returns $self.

=cut

sub remove {
	my $self = shift;
	$self->SUPER::remove($_) for $self->children;
	$self
}

=head2 table

Accessor for the containing L<Tickit::Widget::Table>.

=cut

sub table { shift->{table} }

=head2 selected

Get or set the selection status for this row.

=cut

sub selected {
	my $self = shift;
	if(@_) {
		my $v = shift() ? 1 : 0;
		unless($v == $self->{selected}) {
			$self->{selected} = $v;
			$self->resized;
		}
		return $self;
	}
	return $self->{selected};
}

=head2 cell_type

Default expected cell type for entries in this row.

Typically either L<Tickit::Widget::Table::Cell> or
L<Tickit::Widget::Table::HeaderCell>. Overridden in the
L<Tickit::Widget::Table::HeaderRow> subclass.

=cut

sub cell_type { 'Tickit::Widget::Table::Cell' }

=head2 add_column

Add a new column to the end of the row. You'd think that
maybe there would be a way to add a column in a different
position but no, raise an RT if this is a problem.

=cut

sub add_column {
	my $self = shift;
	my $col = shift;
	my $cell_class = $self->cell_type;
	my $cell = $cell_class->new(
		classes => [ $self->style_classes ],
		table	=> $self->{table},
		row     => $self,
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

sub reposition_cursor { return;
	my $self = shift;
	my $win = $self->window or return;
	$win->focus(0, 0);
}

=head2 update_highlight_style

Ensure all cells are correctly updated on highlight change.

=cut

sub update_highlight_style {
	my $self = shift;
	$_->update_highlight_style(@_) for $self->children;
	$self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011-2013. Licensed under the same terms as Perl itself.
