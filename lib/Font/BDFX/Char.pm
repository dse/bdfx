package Font::BDFX::Char;
use warnings;
use strict;

sub new {
    my ($class, %args) = @_;
    my $self = bless(\%args, $class);
    return $self;
}
sub encoding {
    my ($self) = @_;
}
sub nonstandard_encoding {
    my ($self) = @_;
}
sub swidth {
    my ($self) = @_;
}
sub dwidth {
    my ($self) = @_;
}
sub swidth1 {
    my ($self) = @_;
}
sub dwidth1 {
    my ($self) = @_;
}
sub vvector {
    my ($self) = @_;
}
sub bounding_box {
    my ($self) = @_;
}
sub bitmap_data {
    my ($self) = @_;
}

1;
