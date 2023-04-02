package Font::BDFX;
use warnings;
use strict;

use constant BUILTIN_FONT_INFO => {
    startfont => 1,
    comment => 1,
    contentversion => 1,
    font => 1,
    fontboundingbox => 1,
    metricsset => 1,
    swidth => 1,
    dwidth => 1,
    swidth1 => 1,
    dwidth1 => 1,
    vvector => 1,
    size => 1,
};

sub new {
    my ($class, %args) = @_;
    my $self = bless(\%args, $class);
    return $self;
}

sub set_font_info {
    my ($self, $line, $keyword) = @_;
    $line->{type} = 'font_info';
    $self->{font_info} //= Font::BDFX::Data->new();
    $self->{font_info}->add($line, $keyword);
}

sub set_property {
    my ($self, $line, $keyword) = @_;
    $line->{type} = 'property';
    $self->{properties} //= Font::BDFX::Data->new();
    $self->{properties}->add($line, $keyword);
}

sub set_char_info {
    my ($self, $line, $keyword) = @_;
    $line->{type} = 'char_info';
    return if !defined $self->{char};
    $self->{char}->add($line, $keyword);
}

sub start_char {
    my ($self, $line) = @_;
    my $char = Font::BDFX::Char->new();
    push(@{$self->{chars}}, $char);
}

sub append_comment {
    my ($self, $line) = @_;
    $line->{type} = 'comment';
    push(@{$self->{comments}}, $line);
}

sub add_bitmap_data {
    my ($self, $line) = @_;
    $line->{type} = 'bitmap_data';
    return unless defined $self->{char};
    $self->{char}->add_bitmap_data($line);
}

sub finalize {
    my ($self) = @_;
    # be sure this sub is idempotent.
    my $font_name = $self->get('font');
    if ($font_name =~ m{^(?:-[^-]*){14}$}x) {
        $font_name =~ s{^-}{};
        my @xlfd = split('-', $font_name);
        $self->{xlfd} = [@xlfd];
    }
}

use POSIX qw(round);

# delegation
sub get             { my $self = shift; goto &{ $self->{font_info}->get }; }
sub get_scalar      { my $self = shift; goto &{ $self->{font_info}->get_scalar }; }
sub get_array       { my $self = shift; goto &{ $self->{font_info}->get_array }; }
sub get_string      { my $self = shift; goto &{ $self->{font_info}->get_string }; }
sub get_prop        { my $self = shift; goto &{ $self->{properties}->get }; }
sub get_prop_scalar { my $self = shift; goto &{ $self->{properties}->get_scalar }; }
sub get_prop_array  { my $self = shift; goto &{ $self->{properties}->get_array }; }
sub get_prop_string { my $self = shift; goto &{ $self->{properties}->get_string }; }

# global font info
sub get_startfont {
    my ($self) = @_;
    return $self->get('startfont');
}
sub get_comments {
    my ($self) = @_;
    my @comments = map { $_->{comment_text} } @{$self->{comments}};
    return wantarray ? @comments : [@comments];
}
sub get_contentversion {
    my ($self) = @_;
    return $self->get('contentversion');
}
sub get_font_name {
    my ($self) = @_;
    return $self->get('font');
}
sub get_font_bounding_box {
    my ($self) = @_;
    return $self->get_array('fontboundingbox');
}
sub get_metricsset {
    my ($self) = @_;
    return $self->get('metricsset');
}
sub get_swidth {
    my ($self) = @_;
    return $self->get_array('swidth');
}
sub get_dwidth {
    my ($self) = @_;
    return $self->get_array('dwidth');
}
sub get_swidth1 {
    my ($self) = @_;
    return $self->get_array('swidth1');
}
sub get_dwidth1 {
    my ($self) = @_;
    return $self->get_array('dwidth1');
}
sub get_vvector {
    my ($self) = @_;
    return $self->get_array('vvector');
}

# Special properties that are calculated if not specified in the font
# properties.
sub get_pixel_size {
    my ($self) = @_;
    my $dppi = 722.7;
    return $self->get_prop('pixel_size') // $self->get_xlfd_pixel_size() // $self->calc_pixel_size();
}
sub get_point_size {
    my ($self) = @_;
    return $self->get_prop('point_size') // $self->get_xlfd_point_size() // $self->get_array('size', 0) // $self->calc_point_size();
}
sub get_resolution_x {
    my ($self) = @_;
    return $self->get_prop('resolution_x') // $self->get_xlfd_resolution_x() // $self->get_array('size', 1) // $self->calc_resolution_x();
}
sub get_resolution_y {
    my ($self) = @_;
    return $self->get_prop('resolution_y') // $self->get_xlfd_resolution_y() // $self->get_array('size', 2)// $self->calc_resolution_y();
}

# Methods to calculate font properties we can't find specified
# anywhere in the font.
sub calc_pixel_size {
    my ($self) = @_;
    return round($self->get_resolution_y() * $self->get_point_size() / 722.7);
}
# sub calc_point_size {
#     my ($self) = @_;
#     # Design POINT_SIZE cannot be calculated or approximated.
# }
# sub calc_resolution_x {
#     my ($self) = @_;
#     # RESOLUTION_X cannot be calculated or approximated.
# }
# sub calc_resolution_y {
#     my ($self) = @_;
#     # RESOLUTION_Y cannot be calculated or approximated.
# }

sub get_foundry               { my ($self) = @_; return $self->get_prop('foundry')          // $self->get_xlfd_foundry(); }
sub get_family_name           { my ($self) = @_; return $self->get_prop('family_name')      // $self->get_xlfd_family_name(); }
sub get_weight_name           { my ($self) = @_; return $self->get_prop('weight_name')      // $self->get_xlfd_weight_name() // 'Medium'; }
sub get_slant                 { my ($self) = @_; return $self->get_prop('slant')            // $self->get_xlfd_slant() // 'R'; }
sub get_setwidth_name         { my ($self) = @_; return $self->get_prop('setwidth_name')    // $self->get_xlfd_setwidth_name() // 'Normal'; }
sub get_add_style_name        { my ($self) = @_; return $self->get_prop('add_style_name')   // $self->get_xlfd_add_style_name(); }
sub get_spacing               { my ($self) = @_; return $self->get_prop('spacing')          // $self->get_xlfd_spacing(); }
sub get_average_width         { my ($self) = @_; return $self->get_prop('average_width')    // $self->get_xlfd_average_width(); }
sub get_charset_registry      { my ($self) = @_; return $self->get_prop('charset_registry') // $self->get_xlfd_charset_registry(); }
sub get_charset_encoding      { my ($self) = @_; return $self->get_prop('charset_encoding') // $self->get_xlfd_charset_encoding(); }

# xlfd properties
sub get_xlfd_foundry          { my ($self) = @_; return $self->get_xlfd('foundry', 0); }
sub get_xlfd_family_name      { my ($self) = @_; return $self->get_xlfd('family_name', 1); }
sub get_xlfd_weight_name      { my ($self) = @_; return $self->get_xlfd('weight_name', 2); }
sub get_xlfd_slant            { my ($self) = @_; return $self->get_xlfd('slant', 3); }
sub get_xlfd_setwidth_name    { my ($self) = @_; return $self->get_xlfd('setwidth_name', 4); }
sub get_xlfd_add_style_name   { my ($self) = @_; return $self->get_xlfd('add_style_name', 5); }
sub get_xlfd_pixel_size       { my ($self) = @_; return $self->get_xlfd('pixel_size', 6); }
sub get_xlfd_point_size       { my ($self) = @_; return $self->get_xlfd('point_size', 7); }
sub get_xlfd_resolution_x     { my ($self) = @_; return $self->get_xlfd('resolution_x', 8); }
sub get_xlfd_resolution_y     { my ($self) = @_; return $self->get_xlfd('resolution_y', 9); }
sub get_xlfd_spacing          { my ($self) = @_; return $self->get_xlfd('spacing', 10); }
sub get_xlfd_average_width    { my ($self) = @_; return $self->get_xlfd('average_width', 11); }
sub get_xlfd_charset_registry { my ($self) = @_; return $self->get_xlfd('charset_registry', 12); }
sub get_xlfd_charset_encoding { my ($self) = @_; return $self->get_xlfd('charset_encoding', 13); }
sub get_xlfd {
    my ($self, $prop_name, $prop_number) = @_;
    return $self->get_prop($prop_name) // $self->{xlfd}->[$prop_number];
}

sub as_string {
    my ($self) = @_;
    my $string = '';
    my $startfont      = $self->get_startfont();
    my @comments       = $self->get_comments();
    my $contentversion = $self->get_contentversion();
    my $font_name      = $self->get_font_name();
    my @bbx            = $self->get_font_bounding_box();
    my $metricsset     = $self->get_metricsset();
    my @swidth         = $self->get_swidth();
    my @dwidth         = $self->get_dwidth();
    my @swidth1        = $self->get_swidth1();
    my @dwidth1        = $self->get_dwidth1();
    my @vvector        = $self->get_vvector();
    $string .= "STARTFONT 2.2\n";
    if (!scalar @comments) {
        push(@comments, ' obligatory comment');
    }
    $string .= "COMMENT$_\n" foreach @comments;
    $string .= "CONTENTVERSION $contentversion\n" if defined $contentversion;
    $string .= "FONT $font_name\n"                if defined $font_name;
    $string .= "FONTBOUNDINGBOX @bbx\n"           if scalar @bbx;
    $string .= "METRICSSET $metricsset\n"         if defined $metricsset;
    $string .= "SWIDTH @swidth\n"                 if scalar @swidth;
    $string .= "DWIDTH @dwidth\n"                 if scalar @dwidth;
    $string .= "SWIDTH @swidth1\n"                if scalar @swidth1;
    $string .= "DWIDTH @dwidth1\n"                if scalar @dwidth1;
    $string .= "VVECTOR @vvector\n"               if scalar @vvector;
    my $px_size = $self->get_pixel_size();
    my $pt_size = $self->get_point_size();
    my $res_x = $self->get_resolution_x() // 96;
    my $res_y = $self->get_resolution_y() // 96;
    $string .= "SIZE $pt_size $res_x $res_y\n";
    foreach my $info_line (grep { $_->{type} eq 'font_info' } @{$self->{lines}}) {
        next if BUILTIN_FONT_INFO->{$info_line->{keyword}};
        $string .= $info_line->{text} . "\n";
    }
}



sub trim {
    my ($str) = @_;
    $str =~ s/\A\s+//s;
    $str =~ s/\s+\z//s;
    return $str;
}

1;
