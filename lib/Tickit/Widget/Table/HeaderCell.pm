package Tickit::Widget::Table::HeaderCell;
{
  $Tickit::Widget::Table::HeaderCell::VERSION = '0.002';
}
use strict;
use warnings;
use parent qw(Tickit::Widget::Table::Cell);

=head1 NAME

Tickit::Widget::Table::HeaderCell - header cell for a table

=head1 VERSION

version 0.002

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

=head1 METHODS

=cut

=head2 render

Display the label using the appropriate spacing and attributes

=cut

sub render {
	my $self = shift;
	my $win = $self->window or return;
	my $txt = $self->text;
	my $x = $self->display_xpos;
	$win->goto(0,0);
	$win->print($txt . (' ' x (-$self->table->padding + $self->cols - length $txt)), bg => 4, fg => 7, b => 1);
}

sub new {
	my $class = shift;
	my %args = @_;
	my $table = $args{table};
	my $col = $args{column} or die "No column";
	my $self = $class->SUPER::new(%args, row => 1);
	delete $self->{row};
	$self->{column} = $col;
	$self->{table} = $table;
	return $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
