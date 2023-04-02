package Font::BDFX::Data;
use warnings;
use strict;

sub new {
    my ($class, %args) = @_;
    my $self = bless(\%args, $class);
    (%$self) = (
        %$self,
        string => {},
        array => {},
        scalar => {},
        multi_string => {},
        multi_array => {},
        multi_scalar => {},
    );
    return $self;
}

sub add {
    my ($self, $line, $keyword) = @_;
    my $string = $line->{string};
    my @array  = @{$line->{array}};
    my $scalar = $line->{scalar};
    $self->{string}->{$keyword} = $string; # "<width> <height> <x> <y>"
    $self->{array}->{$keyword} = [@array]; # bbx <width> <height> <x> <y>
    $self->{scalar}->{$keyword} = $array[0]; # <width>
    push(@{$self->{multi_string}->{$keyword}}, $string); # "<width> <height> <x> <y>"
    push(@{$self->{multi_array}->{$keyword}}, [@array]); # bbx <width> <height> <x> <y>
    push(@{$self->{multi_scalar}->{$keyword}}, $array[0]); # <width>
}

sub get {
    my ($self, $keyword, $index) = @_;
    return eval { $self->{array}->{$keyword}->[$index] } if defined $index;
    return $self->{scalar}->{$keyword};
}

sub get_scalar {
    my ($self, $keyword) = @_;
    $self->{scalar}->{$keyword};
}

sub get_array {
    my ($self, $keyword) = @_;
    my $array = eval { $self->{array}->{$keyword} };
    return @$array if defined $array and wantarray;
    return $array;
}

sub get_string {
    my ($self, $keyword) = @_;
    return $self->{string}->{$keyword};
}

1;
