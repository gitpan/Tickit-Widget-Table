package Tickit::Widget::Table::Column;
{
  $Tickit::Widget::Table::Column::VERSION = '0.003';
}
use strict;
use warnings;
use 5.010;
use parent qw(Tickit::Widget Tickit::Widget::Table::Highlight);

use List::Util qw(max);
use List::UtilsBy qw(extract_by);
use POSIX qw(strftime);
use Scalar::Util qw(weaken);
use List::Util qw(max);
use Tickit::Utils qw(textwidth);

=head1 NAME

Tickit::Widget::Table::Column - a column in a L<Ticket::Widget::Table>

=head1 VERSION

version 0.003

=head1 DESCRIPTION

See L<Tickit::Widget::Table>.

A column includes a single header cell, and zero or more data cells.

=cut

=head1 METHODS

=cut

=head2 new

Instantiate a new column.

Takes the following named parameters:

=over 4

=item * table - the L<Tickit::Widget::Table> which will hold this column

=item * label (optional) - a label to use for the header cell, if appropriate

=item * width (optional) - how wide we'd like to be

=item * align (optional) - type of alignment, should be one of left, right, center|centre

=item * format - any formatting to apply. currently a bit vague.

=item * can_highlight - whether this column is highlightable, if not then any
change to highlighting will skip this column.

=back

Returns the new instance.

=cut

sub new {
	my $class = shift;
	my %args = @_;

	my $table = delete $args{table};
	my $label = delete $args{label};
	my $width = delete $args{width};
	my $align = delete $args{align};
	my $format = delete $args{format};
	my $can_highlight = delete $args{can_highlight} // 1;

	my $self = $class->SUPER::new(%args);

	$self->{can_highlight} = $can_highlight;
	$self->{table} = $table;
	weaken $self->{table};
	$self->{data} = $label;
	for($width) {
		when(qr/^\d+$/) { $self->{width_type} = 'fixed'; $self->{width} = $width; }
		when(qr/^\d*\.\d+$/) { $self->{width_type} = 'ratio'; $self->{ratio} = $width; }
		when('min') { $self->{width_type} = 'min'; }
		when('auto') { $self->{width_type} = 'auto'; }
		default { $self->{width_type} = 'auto'; }
	}
	$self->{format} = ref($format) ? $format : $self->format_by_name($format) if $format;
	$self->{align} = $align;
	$self->update_style;
	return $self;
}

{
my %predefined_format = (
	'date'		=> sub {
		my $v = shift;
		defined($v) ? strftime('%Y-%m-%d', $v) : ' '
	},
	'datetime'	=> sub {
		my $v = shift;
		defined($v) ? strftime('%Y-%m-%dT%H:%M:%S', $v) : ' '
	},
	'time'	=> sub {
		my $v = shift;
		defined($v) ? strftime('%H:%M:%S', $v) : ' '
	}
);

=head2 format_by_name

Returns the appropriate format coderef for the given string.

Currently the format can be one of:

=over 4

=item * datetime - %Y-%m-%dT%H:%M:%S

=item * date - %Y-%m-%d

=item * time - %H:%M:%S

=back

=cut

sub format_by_name {
	my $self = shift;
	my $k = shift;
	return $predefined_format{$k};
}

}

=head2 format

Returns the format type for this column.

=cut

sub format { shift->{format} }

=head2 apply_format

Formats the given value according to the requirements of this column's formatting
settings.

=cut

sub apply_format {
	my $self = shift;
	my $v = shift;
	my $code = $self->format;
	$v = $code->($v) if $code;
	$v //= 'undef';
	return $v;
}

=head2 remove_row

Remove the given row from this column.

=cut

sub remove_row {
	my $self = shift;
	my $row = shift;
	my @matched = extract_by { $_ ne $self->{header_cell} && $row eq $_->row } @{$self->{cells}};
	die "More than one match for $row on $self ?" if @matched > 1;
	return $self;
}

=head2 add_header_cell

Attach the given header cell to this column.

=cut

sub add_header_cell {
	my $self = shift;
	my $cell = shift;
	$self->{header_cell} = $cell;
	weaken $self->{header_cell};
	$cell->set_text($self->label);
	return $self;
}

=head2 lines

Number of lines in this widget - since we draw indirectly via cells, this is left as 1.

=cut

sub lines { 1 }

=head2 cols

Returns the number of (screen) columns we'd like to have.

=cut

sub cols {
	my $self = shift;
	my $w = max map $_->cols, $self->cells;
	$w //= 0;
	$w += $self->table->padding;
	return 1 if $self->width_type eq 'auto' && !$w;
	return $w;
}

=head2 width_type

What sort of width this is. Probably something like left|right|auto

=cut

sub width_type { shift->{width_type} // 'auto' }

=head2 width

The width for this column. Should probably return a number.

=cut

sub width { shift->{width} }

=head2 displayed_width

This returns the actual displayed width, i.e. the real number of
(screen) columns used. I think.

=cut

sub displayed_width { shift->{displayed_width} }

=head2 align

Returns the current alignment setting.

=cut

sub align { shift->{align} }

=head2 label

Returns the current label for this column.

=cut

sub label {
	my $self = shift;
	if(@_) {
		my $v = shift;
		$self->{data} = $v;
		$self->header_cell->content($v) if $self->{header_cell};
		return $self;
	}
	return $self->{data};
}

=head2 set_displayed_width

Change the displayed width.

=cut

sub set_displayed_width {
	my $self = shift;
	my $w = shift;
	$self->{displayed_width} = $w;
	for my $child (@{ $self->{cells} }) {
		if(my $win = $child->window) {
			$win->change_geometry($win->top, $win->left, $win->lines, $w);
		} else {
#			$win->change_geometry($win->top, $win->left, $win->lines, $w);
			warn "No window for child $child on $self?";
		}
	}
	return $self;
}

=head2 table

Accessor for the containing L<Tickit::Widget::Table>.

=cut

sub table { shift->{table} }

=head2 add_cell

Adds a new L<Tickit::Widget::Cell> to the end of this column.

=cut

sub add_cell {
	my $self = shift;
	my $cell = shift;
	weaken $cell;
	push @{$self->{cells}}, $cell;
	$cell->{column} = $self;
	weaken $cell->{column};
	return $self;
}

=head2 add_row

Does nothing at all yet has a confusingly purposeful name.

=cut

sub add_row {
	my $self = shift;
}

=head2 autofit

Makes a wild guess as to how wide we should be then sets the displayed width
accordingly.

=cut

sub autofit {
	my $self = shift;
	my $w = max(map { textwidth $_->display_value } @{$self->{cells}});
	$self->set_displayed_width($w);
	return $self;
}

=head2 render

Does nothing, for cases where we're attached to something as a real widget.

=cut

sub render { my $self = shift; return; }

=head2 idx

Our index in the containing L<Tickit::Widget::Table>. Zero-based.

=cut

sub idx {
	my $self = shift;
	my $idx = 0;
	foreach ($self->table->column_list) {
		return $idx if $_ eq $self;
		++$idx;
	}
	die "Not found";
}

#sub lines { 1 }
#sub cols { 1 }
#
#sub new {
#	my $class = shift;
#	my %args = @_;
#	my $tickit = delete $args{tickit};
#	my $self = $class->SUPER::new(%args);
#	$self->{tickit} = $tickit if $tickit;
#	return $self;
#}

=head2 update_style

Updates the pen for all contained cells.

Returns $self.

=cut

sub update_style {
	my $self = shift;
	# TODO use predefined pens or maybe allow undef for defaults
	$_->pen->chattrs($self->table->${\(($self->is_highlighted ? 'highlight' : 'normal') . '_attrs')}) for $self->cells;
	$self
}

=head2 cells

Returns a list of all contained L<Tickit::Widget::Cell> instances.

=cut

sub cells { @{ shift->{cells} || [] } }

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
