package Tickit::Widget::Table::HeaderCell;
{
  $Tickit::Widget::Table::HeaderCell::VERSION = '0.100';
}
use strict;
use warnings;
use parent qw(Tickit::Widget::Table::Cell);

=head1 NAME

Tickit::Widget::Table::HeaderCell - header cell for a table

=head1 VERSION

version 0.100

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Tickit::Utils qw(textwidth);

use Tickit::Style;

BEGIN {
	style_definition base =>
		fg => 'white',
		bg => 'blue',
		b => 1,
		spacing => 0;
}

=head1 METHODS

=cut

=head2 new

Instantiate a new header cell.

=cut

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
