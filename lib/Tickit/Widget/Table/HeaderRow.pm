package Tickit::Widget::Table::HeaderRow;
{
  $Tickit::Widget::Table::HeaderRow::VERSION = '0.100';
}
use strict;
use warnings;
use parent qw(Tickit::Widget::Table::Row);

use Tickit::Widget::Table::HeaderCell;

=head1 NAME

Tickit::Widget::Table::HeaderRow - header row, like a normal row but has a cell

=head1 VERSION

version 0.100

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

=head1 METHODS

=cut

sub cell_type { 'Tickit::Widget::Table::HeaderCell' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
