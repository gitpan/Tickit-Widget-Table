package Tickit::Widget::Table::Column;
{
  $Tickit::Widget::Table::Column::VERSION = '0.001';
}
use strict;
use warnings;
use 5.010;
use parent qw(Tickit::Widget);

use List::Util qw(max);
use List::UtilsBy qw(extract_by);
use POSIX qw(strftime);
use Scalar::Util qw(weaken);

=head1 NAME



=head1 SYNOPSIS

=head1 VERSION

version 0.001

=head1 DESCRIPTION

=cut

=head1 METHODS

=cut

=pod

A column includes a single header cell, and zero or more data cells.

=cut

sub new {
	my $class = shift;
	my %args = @_;

	my $table = delete $args{table};
	my $label = delete $args{label};
	my $width = delete $args{width};
	my $align = delete $args{align};
	my $format = delete $args{format};

	my $self = $class->SUPER::new(%args);

	$self->{table} = $table;
	weaken $self->{table};
	$self->{data} = $label;
	given($width) {
		when(qr/^\d+$/) { $self->{width_type} = 'fixed'; $self->{width} = $width; }
		when(qr/^\d*\.\d+$/) { $self->{width_type} = 'ratio'; $self->{ratio} = $width; }
		when('auto') { $self->{width_type} = 'auto'; }
		default { $self->{width_type} = 'auto'; }
	}
	$self->{format} = ref($format) ? $format : $self->format_by_name($format) if $format;
	$self->{align} = $align;
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
sub format_by_name {
	my $self = shift;
	my $k = shift;
	return $predefined_format{$k};
}

}
sub format { shift->{format} }
sub apply_format {
	my $self = shift;
	my $v = shift;
	my $code = $self->format;
	$v = $code->($v) if $code;
	$v //= 'undef';
	return $v;
}

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

sub cols { my $self = shift; $self->displayed_width // $self->width // 6; }

sub width_type { shift->{width_type} // 'auto' }

sub width { shift->{width} }

sub displayed_width { shift->{displayed_width} }

sub align { shift->{align} }

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

sub set_displayed_width {
	my $self = shift;
	my $w = shift;
	$self->{displayed_width} = $w;
	$_->resized for @{ $self->{cells} };
	return $self;
}

sub table { shift->{table} }

sub add_cell {
	my $self = shift;
	my $cell = shift;
	weaken $cell;
	push @{$self->{cells}}, $cell;
	$cell->{column} = $self;
	weaken $cell->{column};
	return $self;
}

sub add_row {
	my $self = shift;
}

sub autofit {
	my $self = shift;
	my $w = max(map { length $_->display_value } @{$self->{cells}});
	$self->set_displayed_width($w);
	return $self;
}

sub render { my $self = shift; return; }

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

1;

=pod

fixed => 8
ratio => 0.5

=cut

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
