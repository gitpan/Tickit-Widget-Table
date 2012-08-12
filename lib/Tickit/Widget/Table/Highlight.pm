package Tickit::Widget::Table::Highlight;
{
  $Tickit::Widget::Table::Highlight::VERSION = '0.003';
}
use strict;
use warnings;

=head1 NAME


=head1 VERSION

version 0.003
Tickit::Widget::Table::Highlight - highlight functionality for
cells, rows and columns in a table

=head1 DESCRIPTION

This is a mixin which allows various classes under L<Tickit::Widget::Table>
to provide a common interface for highlighting.

=head1 METHODS

=cut

=head2 highlighted

Get or set highlight status for this item.

Only one item can be highlighted at a time.

=cut

sub highlighted {
	my $self = shift;
	if(@_) {
		my $v = shift;
		if($v ~~ $self->{highlighted}) {
			$self->{highlighted} = $v;
		} else {
			$self->{highlighted} = $v;
			$self->update_style;
		}
		return $self;
	}
	return $self->{highlighted};
}

=head2 is_highlighted

Returns true if this item is highlighted.

=cut

sub is_highlighted { shift->{highlighted} ? 1 : 0 }

=head2 is_selected

Returns true if this item is selected.

=cut

sub is_selected { shift->{selected} ? 1 : 0 }

=head2 action

Get or set the action for this item. An "action" is a coderef
called when the item is activated, typically by clicking or
hitting enter when the item is highlighted and the table is in
the appropriate highlight_mode.

=cut

sub action {
	my $self = shift;
	if(@_) {
		$self->{action} = shift;
		return $self;
	}
	return $self->{action};
}

=head2 activate

Call this to trigger the appropriate activation logic.

Returns $self.

=cut

sub activate {
	my $self = shift;
	my $code = $self->action // $self->table->default_action or return $self;
	$code->($self->table);
	$self
}

=head2 can_highlight

Returns true if this instance has the ability to be highlighted.

Will be false for 'hidden' columns/rows/cells, in which case we'd
expect the highlighting logic to skip right over them as if they
never existed.

=cut

sub can_highlight { shift->{can_highlight} }

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
