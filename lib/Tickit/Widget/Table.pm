package Tickit::Widget::Table;
# ABSTRACT: Table widget
use strict;
use warnings;
use parent qw(Tickit::Widget::VBox);

our $VERSION = '0.001';

=head1 NAME

Tickit::Widget::Table - tabular widget support for L<Tickit>

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use Tickit::Widget::Table;
 # Create the widget
 my $table = Tickit::Widget::Table->new(
 	padding => 1,
	columns => [
	],
	data	=> [
	],
 );
 # Put it in something
 my $container = Tickit::Widget::HBox->new;
 $container->add($table, expand => 1);

=head1 DESCRIPTION



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

=item * default_cell_action - coderef to execute when a cell
is activated unless there is an action defined on the cell,
row or column.

=item * default_row_action - coderef to execute when a row
is activated.

=item * header - flag to select whether a header is shown. If not provided it is assumed that a header is wanted.

=back

=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $columns = delete $args{columns};
	my $padding = delete $args{padding};
	my $header = exists $args{header} ? delete $args{header} : 1;
	my $cell_action = delete $args{default_cell_action};
	my $row_action = delete $args{default_cell_action};
	my $self = $class->SUPER::new(%args);
	$self->{columns} = [];
	$self->{padding} = $padding // 0;
	$self->{default_cell_action} = $cell_action;
	$self->{default_row_action} = $row_action;

	$self->add_initial_columns($columns);
	$self->add_header_row($header) if $header;
	return $self;
}

=head2 add_header_row

Adds a header row to the top of the table.

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

=cut

sub padding { shift->{padding} }

=head2 lines

=cut

sub lines { scalar(shift->children) }

=head2 cols

=cut

sub cols {
	my $self = shift;
	my $w = 0;
	$w += $_->cols for $self->column_list;
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

=cut

sub columns { scalar(shift->column_list) }

=head2 data_rows

=cut

sub data_rows {
	my $self = shift;
	my @children = $self->children;
	# Ignore the first if we have a header
	shift @children if $self->{header_row};
	return @children;
}

=head2 reposition_cursor

=cut

sub reposition_cursor {
	my $self = shift;
	my $row = $self->highlight_row or return;
	$row->reposition_cursor;
}

=head2 header_row

=cut

sub header_row {
	my $self = shift;
	return unless $self->{header_row};
	return ($self->children)[0];
}

=head2 set_highlighted_row

=cut

sub set_highlighted_row {
	my $self = shift;
	my $id = shift;
	my $idx = 0;

	delete $self->{highlight};
	delete $self->{highlight_row};

	foreach my $row ($self->data_rows) {
		if($id == $idx) {
			my $redraw = !$row->{highlighted};
			$row->highlighted(1);
			$self->{highlight} = $id;
			$self->{highlight_row} = $row;
			$row->redraw if $redraw;
		} else {
			my $redraw = $row->{highlighted};
			$row->highlighted(0);
			$row->redraw if $redraw;
		}
		++$idx;
	}
	$self->reposition_cursor;
	return $self;
}

=head2 highlight_row

=cut

sub highlight_row {
	my $self = shift;
	return $self->{highlight_row};
}

=head2 highlight_row_index

=cut

sub highlight_row_index {
	my $self = shift;
	return $self->{highlight};
}

=pod

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
	return unless @auto;

	my $remaining = $self->window->cols - $htotal;
	my $per_column = $remaining / @auto;
	foreach my $col (@auto) {
		my $w = floor(min($remaining, $per_column));
		$col->set_displayed_width($w);
		$remaining -= $w;
	}
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

	$_->set_displayed_width(1) for grep { defined $self->get_column_width($_) } $self->column_list;
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
	return $col;
}

=head2 add_row

Adds a new row of data to the table. This will instantiate
a new L<Tickit::Widget::Table::Row> and return it.

=cut

sub add_row {
	my $self = shift;

# Instantiate the row using parameters as the cell values
	my $row = Tickit::Widget::Table::Row->new(
		table	=> $self,
		column	=> [ $self->column_list ],
		data	=> [ @_ ],
	);
	$self->add($row);

# Add link back to the row for each of the columns
	$_->add_row($row) for $self->column_list;

# If nothing has been highlighted yet then highlight the
# first row - might be us
	$self->set_highlighted_row(0) unless $self->highlight_row;
	$self->resized;
	return $row;
}

=head2 remove_row

=cut

sub remove_row {
	my $self = shift;
	my $row = shift;

# Work out which row index we are, since we may need to update
# the highlighted row
	my @c = $self->data_rows;
	my ($idx) = grep { $c[$_] eq $row } 0..$#c;
	warn "Remove row $row idx $idx of " . $self->rows . "\n";

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

=head2 on_key

Key handling: convert some common key requests to events.

=cut

sub on_key {
	my $self = shift;
	my ($type, $str, $key) = @_;
	return if $self->{on_key} && !$self->{on_key}->(@_);

	if($type eq 'key') {
		$self->on_quit if $str eq 'C-q';
		$self->on_cursor_up if $str eq 'Up';
		$self->on_cursor_pageup if $str eq 'PageUp';
		$self->on_cursor_down if $str eq 'Down';
		$self->on_cursor_pagedown if $str eq 'PageDown';
		$self->on_cursor_home if $str eq 'Home';
		$self->on_cursor_end if $str eq 'End';
		$self->on_key_insert if $str eq 'Insert';
		$self->on_key_delete if $str eq 'Delete';
		$self->on_toggle_select_all if $str eq 'M-a';
		$self->on_switch_window if $str eq 'Tab';
		if($str eq 'Enter') {
			$self->on_activate_cell; # if $self->{default_cell_action};
			$self->on_activate_row; # if $self->{default_row_action};
		}
	} elsif($type eq 'text') {
		$self->on_select if $str eq ' ';
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

uh, no.

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
	$self->add_row(
		"Some file " . (rand(time)) . '.txt',
		rand(time),
		'file',
		DateTime->from_epoch(epoch => rand(time))->strftime('%Y-%m-%d %H:%M:%S')
	);
}

=head2 on_key_delete

Should not be here.

=cut

sub on_key_delete {
	my $self = shift;
	$self->remove_row($self->highlight_row);
}

=head2 on_cursor_up

Move to the row above.

=cut

sub on_cursor_up {
	my $self = shift;
	my $idx = $self->highlight_row_index;
	$idx = $self->rows - 1 if --$idx < 0;
	$self->set_highlighted_row($idx);
}

=head2 on_cursor_home

Move to the top of the table.

=cut

sub on_cursor_home {
	my $self = shift;
	$self->set_highlighted_row(0);
}

=head2 on_cursor_end

Move to the end of the table.

=cut

sub on_cursor_end {
	my $self = shift;
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
	my $idx = $self->highlight_row_index;
	$idx = 0 if ++$idx >= $self->rows;
	$self->set_highlighted_row($idx);
}

=head2 on_cursor_pagedown

Move several lines down.

=cut

sub on_cursor_pagedown {
	my $self = shift;
	my $idx = $self->highlight_row_index;
	$idx += 10;
	$idx -= $self->rows - 1 if $idx >= $self->rows;
	$self->set_highlighted_row($idx);
}

sub on_activate_cell {
	my $self = shift;
	if(my $code = $self->{default_cell_action}) {
		$code->($self);
	} else {
		warn "No default action for $self\n";
	}
	return 1;
}

sub on_activate_row {
	my $self = shift;
	my $code = $self->highlight_row->action;
	$code ||= $self->{default_row_action};
#	die "No code\n" unless $code;
	return 1 unless $code;

	$code->($self, row => $self->highlight_row);
	return 1;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
