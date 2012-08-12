package Tickit::Widget::Table;
# ABSTRACT: Table widget
use strict;
use warnings;
use parent qw(Tickit::Widget::VBox);
use Scalar::Util qw(weaken);
use List::Util qw(max sum);

our $VERSION = '0.003';

=head1 NAME

Tickit::Widget::Table - tabular widget support for L<Tickit>

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 use Tickit::Widget::HBox;
 use Tickit::Widget::Table;
 # Create the widget
 my $table = Tickit::Widget::Table->new(
 	padding => 1,
	columns => [
		{ label => 'First column', align => 'center', width => 'auto' },
		{ label => 'Second column', align => 'right', width => 'auto' },
	],
 );
 $table->add_row(
 	'First entry',
	'Second column',
 );
 $table->add_row(
 	'Second entry',
	'More data',
 );
 # Put it in something
 my $container = Tickit::Widget::HBox->new;
 $container->add($table, expand => 1);

=head1 DESCRIPTION

Basic support for table widgets. See examples/ in the main distribution for usage
instructions.

=cut

use List::Util qw(min);
use POSIX qw(floor);

use Tickit::Widget::Table::HeaderRow;
use Tickit::Widget::Table::Cell;
use Tickit::Widget::Table::Column;
use Tickit::Widget::Table::Row;

=head1 METHODS

=head2 new

Create a new table widget.

Takes the following named parameters:

=over 4

=item * columns - column definition arrayref, see L</add_column> for the details

=item * padding - amount of padding (in chars) to apply between columns

=item * default_action - coderef to execute when a cell/row/column
is activated, unless there is an action defined on that item already

=item * header - flag to select whether a header is shown. If not provided it is
assumed that a header is wanted.

=item * highlight_mode - one of row (default), column, cell, defines how navigation
and selection work

=back

=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $columns = delete $args{columns};
	my $padding = delete $args{padding} // 0;
	my $header = exists $args{header} ? delete $args{header} : 1;
	my $default_action = delete $args{default_action};
	my $highlight_mode = delete $args{highlight_mode} // 'row';
	my $self = $class->SUPER::new(%args);
	$self->{highlight_mode} = $highlight_mode;
	$self->{columns} = [];
	$self->{padding} = $padding;
	$self->{default_action} = $default_action;

	$self->add_initial_columns($columns);
	$self->add_header_row($header) if $header;
	return $self;
}

=head2 add_header_row

Adds a header row to the top of the table. Takes no parameters.

=cut

sub add_header_row {
	my $self = shift;
	return if $self->{header_row};

	my $header_row = Tickit::Widget::Table::HeaderRow->new(
		table	=> $self,
		column	=> [ $self->column_list ]
	);
	$self->add($header_row);
	$self->{header_row} = $header_row;
	my $idx = 0;
	$_->add_header_cell($header_row->cell($idx++)) for $self->column_list;
	return $self;
}

=head2 add_initial_columns

Populates initial columns from the given arrayref. Generally handled
internally when passing C< columns > in the constructor.

=cut

sub add_initial_columns {
	my $self = shift;
	my $columns = shift;
	$self->add_column(
		%$_,
		refit_later => 1,
	) for @{$columns // []};
}

=head2 padding

Returns amount of padding between cells

=cut

sub padding { shift->{padding} }

=head2 lines

Number of rows.

=cut

sub lines { scalar(shift->children) }

=head2 cols

Number of screen columns.

=cut

sub cols {
	my $self = shift;
	my $w = sum map $_->cols, $self->column_list;
	return $w || 1;
}

=head2 rows

'rows' are the number of data rows we have in the table. That's one less
than the total number of rows if we have a header row

=cut

sub rows {
	my $self = shift;
	my $count = scalar($self->children);
	--$count if $self->{header_row};
	return $count
}

=head2 columns

Number of columns in the table.

=cut

sub columns { scalar(shift->column_list) }

=head2 data_rows

Returns the rows containing data - this excludes the header row if there is
one.

=cut

sub data_rows {
	my $self = shift;
	my @children = $self->children;
	# Ignore the first if we have a header
	shift @children if $self->{header_row};
	return @children;
}

=head2 reposition_cursor

Put the cursor in the right place. Possibly used internally, probably of
dubious utility.

=cut

sub reposition_cursor {
	my $self = shift;
	$self->{on_highlight_changed}->($self) if $self->{on_highlight_changed};
	$self
#	my $row = $self->highlight_row or return;
#	my $col = $self->highlight_col or return;
#	$row->reposition_cursor;
}

=head2 header_row

Returns the header row if there is one.

=cut

sub header_row {
	my $self = shift;
	return unless $self->{header_row};
	return +($self->children)[0];
}

=head2 set_highlighted_row

Highlight a row in the table. Only one row can be highlighted at a time,
as opposed to selected rows.

=cut

sub set_highlighted_row {
	my $self = shift;
	my $id = shift;

	delete $self->{highlight_row};
	delete $self->{highlight_row_index};

	my $idx = 0;
	foreach my $row ($self->data_rows) {
		if($id == $idx) {
			my $redraw = !$row->is_highlighted;
			$row->highlighted(1);
			$self->{highlight_row_index} = $id;
			$self->{highlight_row} = $row;
			$row->redraw if $redraw;
		} else {
			my $redraw = $row->is_highlighted;
			$row->highlighted(0);
			$row->redraw if $redraw;
		}
		++$idx;
	}
	$self->reposition_cursor;
	return $self;
}

=head2 set_highlighted_column

Highlight a row in the table. Only one row can be highlighted at a time,
as opposed to selected rows.

=cut

sub set_highlighted_column {
	my $self = shift;
	my $id = shift;

	delete $self->{highlight_column};
	delete $self->{highlight_column_index};

	my $idx = 0;
	foreach my $col ($self->column_list) {
		if($id == $idx) {
			my $redraw = !$col->is_highlighted;
			$col->highlighted(1);
			$self->{highlight_column_index} = $id;
			$self->{highlight_column} = $col;
			$col->redraw if $redraw;
		} else {
			my $redraw = $col->is_highlighted;
			$col->highlighted(0);
			$col->redraw if $redraw;
		}
		++$idx;
	}
	$self->reposition_cursor;
	return $self;
}

=head2 highlight_row

Returns currently-highlighted row, if we have one.
In cell mode, returns the row corresponding to current cell highlight.

=cut

sub highlight_row {
	my $self = shift;
	return $self->{highlight_row};
}

=head2 highlight_column

Returns currently-highlighted column, if we have one.
In cell mode, returns the column corresponding to current cell highlight.

=cut

sub highlight_column {
	my $self = shift;
	return $self->{highlight_column};
}

=head2 highlight_cell

=cut

sub highlight_cell {
	my $self = shift;
	return $self->{highlight_cell};
}

=head2 highlighted_item

=cut

sub highlighted_item {
	my $self = shift;
	my $type = $self->highlight_mode;
	$self->{'highlight_' . $type}
}

=head2 highlight_row_index

Index of the currently-highlighted row.

=cut

sub highlight_row_index { shift->{highlight_row_index} }

=head2 highlight_column_index

Index of the currently-highlighted column.

=cut

sub highlight_column_index { shift->{highlight_column_index} }

=head2 refit

Check current widths and apply width on columns we already have sufficient information for.

=cut

sub refit {
	my $self = shift;
	return unless $self->window;

# Horizontal total for existing columns
	my $htotal = 0;

	my @auto;
	COL:
	foreach my $col ($self->column_list) {
		my $w = $self->get_column_width($col);
		unless(defined $w) {
			push @auto, $col;
			next COL;
		}

		$w ||= 1;
		$col->set_displayed_width($w);
		$htotal += $w;
	}
	unless(@auto) {
		$self->resized;
		return $self;
	}

	my $remaining = $self->window->cols - $htotal;
	my $per_column = $remaining / @auto;
	foreach my $col (@auto) {
		my $w = floor min $remaining, $per_column;
		$col->set_displayed_width($w);
		$remaining -= $w;
	}
	$self->resized;
	return $self;
}

=head2 min_refit

Try to shrink columns down to minimum possible width if they're
flexible. Typically used by L</add_column> to allow the new
column to fit properly.

=cut

sub min_refit {
	my $self = shift;
	return unless $self->window;

	$_->set_displayed_width(1) for grep defined $self->get_column_width($_), $self->column_list;
	return $self;
}

=head2 get_column_width

Return the width for the given column, or undef if this
column should be autosized.

=cut

sub get_column_width {
	my ($self, $col) = @_;
	if($col->width_type eq 'fixed') {
		return $col->width;	
	} elsif($col->width_type eq 'min') {
		return 1 + max map $_->display_width, $col->cells;
	} elsif($col->width_type eq 'ratio') {
		return $self->window->cols * $col->width_ratio;
	}
	return undef;
}

=head2 column_list

Returns all columns for this table as a list.

=cut

sub column_list {
	my $self = shift;
	return @{ $self->{columns} };
}

=head2 add_column

Add a new column to the table, returning a
L<Tickit::Widget::Table::Column> instance.

=cut

sub add_column {
	my $self = shift;
	my %args = @_;

# HAX Crush everything down to minimum possible size first
	$self->min_refit unless $args{refit_later};

# Instantiate if we can
	my $col = Tickit::Widget::Table::Column->new(
		table	=> $self,
		%args
	);

# Add this to our columns and link all rows to this column
	push @{ $self->{columns} }, $col;
	$_->add_column($col) for $self->children;

# Put in a header cell as well if we have a header
	$col->add_header_cell($self->header_row->cell(scalar(@{ $self->{columns} })-1)) if $self->{header_row};

# Now we should have enough information to refit if we're going to
	$self->refit unless $args{refit_later};
	$self->update_highlight unless $self->highlighted_item;
	return $col;
}

=head2 update_highlight

=cut

sub update_highlight {
	my $self = shift;
	if($self->highlight_mode eq 'row') {
		$self->set_highlighted_row(0) unless $self->highlight_row;
	} elsif($self->highlight_mode eq 'column') {
		$self->set_highlighted_column(0) unless $self->highlight_column;
	} else {
		$self->set_highlighted_cell(0, 0) unless $self->highlight_cell;
	}
	$self
}

=head2 add_row

Adds a new row of data to the table. This will instantiate
a new L<Tickit::Widget::Table::Row> and return it.

=cut

sub add_row {
	my $self = shift;
	my %args = @_;

# Instantiate the row using parameters as the cell values
	my $row = Tickit::Widget::Table::Row->new(
		table	=> $self,
		column	=> [ $self->column_list ],
		can_highlight => $args{can_highlight},
		data	=> $args{data} || [],
	);
	$self->add($row);

# Add link back to the row for each of the columns
	$_->add_row($row) for $self->column_list;

# If nothing has been highlighted yet then highlight the
# first row - might be us
	$self->update_highlight unless $self->highlighted_item;
	$self->resized;
	return $row;
}

=head2 remove_row

Remove the given row.

=cut

sub remove_row {
	my $self = shift;
	my $row = shift;

# Work out which row index we are, since we may need to update
# the highlighted row
	my @c = $self->data_rows;
	my ($idx) = grep { $c[$_] eq $row } 0..$#c;

# If this is the highlighted row then adjust highlight to the
# row above instead.
	if($self->highlight_row eq $row) {
		--$idx;
		$self->set_highlighted_row(($idx < 0) ? 0 : $idx);
	}

# Do the actual removal
	$self->remove($row);
	$self->resized;
}

=head2 clear_data

Clears any data for this table, leaving structure including header row intact.

=cut

sub clear_data {
	my $self = shift;
	$_->remove for $self->data_rows;
	$self->resized;
	return $self;
}

=head2 window_gained

Once we have a window, we want to refit to ensure that all the child elements
are given subwindows with appropriate geometry.

=cut

sub window_gained {
	my $self = shift;
	$self->SUPER::window_gained(@_);
	$self->refit;
}

=head2 window_lost

When the main window is lost, we also clear all the subwindows that were created for children.

=cut

sub window_lost {
	my $self = shift;
	$self->SUPER::window_lost(@_);
	$_->set_window(undef) for $self->children;
}

{ # put ->on_key in a little scope of its own
my %key_map = (
	'C-q' => 'on_quit',
	'Up' => 'on_cursor_up',
	'PageUp' => 'on_cursor_pageup',
	'Down' => 'on_cursor_down',
	'PageDown' => 'on_cursor_pagedown',
	'Home' => 'on_cursor_home',
	'End' => 'on_cursor_end',
	'Left' => 'on_cursor_left',
	'Right' => 'on_cursor_right',
	'Insert' => 'on_key_insert',
	'Delete' => 'on_key_delete',
	'M-a' => 'on_toggle_select_all',
	'Tab' => 'on_switch_window',
);
my %text_map = (
	' ' => 'on_select',
);

=head2 on_key

Key handling: convert some common key requests to events.

=cut

sub on_key {
	my $self = shift;
	my ($type, $str) = @_; # $key isn't used here. yet.
	return 1 if $self->{on_key} && !$self->{on_key}->(@_);

	if($type eq 'key') {
		if(defined(my $method = $key_map{$str})) {
			$self->$method;
			return 1;
		}
		if($str eq 'Enter') {
			$self->highlighted_item->activate;
			return 1;
		}
	} elsif($type eq 'text') {
		if(defined(my $method = $text_map{$str})) {
			$self->$method;
			return 1;
		}
	}
	return 0;
}
}

=head2 on_quit

Handle a quit request. This is clearly not the place to have
code like this.

=cut

sub on_quit {
	my $self = shift;
	my $loop = $self->window->root->{tickit}->get_loop;
	weaken $loop;
	$loop->later(sub { $loop->loop_stop; });
}

=head2 on_switch_window

uh, no. you didn't see this.

=cut

sub on_switch_window {
	my $self = shift;
	$self->table->parent->{on_tab}->() if $self->table->parent->{on_tab};
}

=head2 on_toggle_select_all

Select everything, unless everything is already selected in which case select nothing instead.

=cut

sub on_toggle_select_all {
	my $self = shift;

# If the number selected matches the total, then we need to deselect.
	if($self->data_rows == grep { $_->{selected} } $self->data_rows) {
		$_->selected(0) for grep { $_->is_selected } $self->table->data_rows;
	} else {
		$_->selected(1) for grep { !$_->is_selected } $self->data_rows;
	}
	return $self;
}

=head2 on_select

Toggle selection for this row.

=cut

sub on_select {
	my $self = shift;
	$self->highlight_row->selected(!$self->highlight_row->selected);
	return $self;
}

=head2 on_key_insert

Should not be here.

=cut

sub on_key_insert {
	my $self = shift;
}

=head2 on_key_delete

Should not be here.

=cut

sub on_key_delete {
	my $self = shift;
}

=head2 on_cursor_up

Move to the row above.

=cut

sub on_cursor_up {
	my $self = shift;
	# No vertical navigation in column mode
	return $self if $self->highlight_mode eq 'column';

	my %seen;
	ROW:
	do {
		my $idx = $self->highlight_row_index;
		$idx = $self->rows - 1 if --$idx < 0;
		$self->set_highlighted_row($idx);
		last ROW if $seen{$idx}++;
	} until $self->highlight_row->can_highlight;
}

=head2 on_cursor_home

Move to the top of the table.

=cut

sub on_cursor_home {
	my $self = shift;
	# No vertical navigation in column mode
	return $self if $self->highlight_mode eq 'column';

	$self->set_highlighted_row(0);
}

=head2 on_cursor_end

Move to the end of the table.

=cut

sub on_cursor_end {
	my $self = shift;
	# No vertical navigation in column mode
	return $self if $self->highlight_mode eq 'column';

	$self->set_highlighted_row($self->rows - 1);
}

=head2 on_cursor_pageup

Move several lines up.

=cut

sub on_cursor_pageup {
	my $self = shift;
	my $idx = $self->highlight_row_index;
	$idx -= 10;
	$idx += $self->rows - 1 if $idx < 0;
	$self->set_highlighted_row($idx);
}

=head2 on_cursor_down

Move one line down.

=cut

sub on_cursor_down {
	my $self = shift;
	# No vertical navigation in column mode
	return $self if $self->highlight_mode eq 'column';

	my %seen;
	ROW:
	do {
		my $idx = $self->highlight_row_index;
		$idx = 0 if ++$idx >= $self->rows;
		$self->set_highlighted_row($idx);
		last ROW if $seen{$idx}++;
	} until $self->highlight_row->can_highlight;
}

=head2 on_cursor_pagedown

Move several lines down.

=cut

sub on_cursor_pagedown {
	my $self = shift;
	# No vertical navigation in column mode
	return $self if $self->highlight_mode eq 'column';

	my $idx = $self->highlight_row_index;
	$idx += 10;
	$idx -= $self->rows - 1 if $idx >= $self->rows;
	$self->set_highlighted_row($idx);
}

=head2 on_cursor_left

Move to the item on the left.

=cut

sub on_cursor_left {
	my $self = shift;
	return $self if $self->highlight_mode eq 'row';

	my %seen;
	COL:
	do {
		my $idx = $self->highlight_column_index;
		$idx = $self->columns - 1 if --$idx < 0;
		$self->set_highlighted_column($idx);
		last COL if $seen{$idx}++;
	} until $self->highlight_column->can_highlight;
}

=head2 on_cursor_right

Move to the item on the right.

=cut

sub on_cursor_right {
	my $self = shift;
	return $self if $self->highlight_mode eq 'row';

	my %seen;
	COL:
	do {
		my $idx = $self->highlight_column_index;
		$idx = ++$idx % $self->columns;
		$self->set_highlighted_column($idx);
		last COL if $seen{$idx}++;
	} until $self->highlight_column->can_highlight;
}

=head2 highlight_mode

=cut

sub highlight_mode {
	my $self = shift;
	if(@_) {
		$self->{highlight_mode} = shift;
		return $self;
	}
	$self->{highlight_mode}
}

=head2 default_action

=cut

sub default_action {
	my $self = shift;
	if(@_) {
		$self->{default_action} = shift;
		return $self;
	}
	$self->{default_action}
}

=head2 bind_key

Accessor/mutator for the C<on_key> callback.

Returns $self when used as a mutator, or the current C<on_key> value when
called with no parameters.

=cut

sub bind_key {
	my $self = shift;
	if(@_) {
		$self->{on_key} = shift;
		return $self;
	}
	$self->{on_key}
}

=head2 on_highlight_changed

Accessor/mutator for the C<on_highlight_changed> callback.

Returns $self when used as a mutator, or the current C<on_highlight_changed> value when
called with no parameters.

=cut

sub on_highlight_changed {
	my $self = shift;
	if(@_) {
		$self->{on_highlight_changed} = shift;
		return $self;
	}
	$self->{on_highlight_changed}
}

=head2 highlight_attrs

Accessor for pen attributes to use for highlighted cells, as a hashref.

=cut

sub highlight_attrs { +{ fg => 6, b => 1, bg => 4 } }

=head2 normal_attrs

Accessor for pen attributes to use for unhighlighted cells, as a hashref.

=cut

sub normal_attrs { +{ fg => 7, bg => 4, b => 0 } }

=head2 reshape

Called when the window has been resized. Recalculates layout.

=cut

sub reshape {
	my $self = shift;
	warn "Reshape";
	$self->refit;
	$self->SUPER::reshape;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
