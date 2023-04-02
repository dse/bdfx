ipackage Font::BDFX::Parser;
use warnings;
use strict;

use v5.10.1;
use feature qw(switch);

sub new {
    my ($class, %args) = @_;
    my $self = bless(\%args, $class);
    (%$self) = (
        stage => 'info',
        bdfx => Font::BDFX->new(),
        %$self,                 # caller-specified arguments override
                                # defaults above.
    );
    return $self;
}

sub parse_line {
    my ($self, $text) = @_;
    my $bdfx = $self->{bdfx};
    local $_ = $text;
    my $line = {
        text => $_
    };
    push(@{$bdfx->{lines}}, $line);
    s/\R\z//;                   # also trims \r\n unlike chomp
    if (!/\S/) {
        $line->{type} = 'blank';
        return;
    }
    if (/^\s*#/) {
        $line->{type} = 'comment';
        return;
    }
    my $keyword;
    if (s/^\s*(?<keyword>\S+)//) {
        $keyword = lc($+{keyword});
    }
    $line->{keyword} = $keyword;
    my $remaining_text = $line->{remaining_text} = $_;

    my @array = split(' ', $remaining_text);
    my $scalar = $array[0];
    my $string = $remaining_text;
    $string = trim($string);

    $line->{array} = [@array];
    $line->{scalar} = $scalar;
    $line->{string} = $string;

    if ($self->{stage} eq 'info') {
        $self->parse_info_stage_line($line, $keyword);
    } elsif ($self->{stage} eq 'properties') {
        $self->parse_properties_stage_line($line, $keyword);
    } elsif ($self->{stage} eq 'chars') {
        $self->parse_chars_stage_line($line, $keyword);
    } elsif ($self->{stage} eq 'char') {
        $self->parse_char_stage_line($line, $keyword);
    } elsif ($self->{stage} eq 'bitmap') {
        $self->parse_bitmap_stage_line($line, $keyword);
    } elsif ($self->{stage} eq 'eof') {
        $self->parse_eof_stage_line($line, $keyword);
    }
}

sub parse_info_stage_line {
    my ($self, $line, $keyword) = @_;
    if ($keyword eq 'startproperties') {
        $self->{stage} = 'properties'; return;
    }
    if ($keyword eq 'chars') {
        $self->{stage} = 'chars'; return;
    }
    if ($keyword eq 'startchar') {
        $self->{bdfx}->start_char($line);
        $self->{stage} = 'char'; return;
    }
    if ($keyword eq 'endfont') {
        $self->{stage} = 'eof'; return;
    }
    if ($keyword eq 'comment') {
        $line->{comment_text} = $line->{remaining_text};
        $self->{bdfx}->append_comment($line);
        return;
    }
    $self->{bdfx}->set_font_info($line, $keyword);
}

sub parse_properties_stage_line {
    my ($self, $line, $keyword) = @_;
    if ($keyword eq 'endproperties') {
        $self->{stage} = 'info'; return;
    }
    if ($keyword eq 'chars') {
        $self->{stage} = 'chars'; return;
    }
    if ($keyword eq 'startchar') {
        $self->{bdfx}->start_char($line);
        $self->{stage} = 'char'; return;
    }
    if ($keyword eq 'endfont') {
        $self->{stage} = 'eof'; return;
    }
    $self->{bdfx}->set_property($line, $keyword);
}

sub parse_chars_stage_line {
    my ($self, $line, $keyword) = @_;
    if ($keyword eq 'startchar') {
        $self->{bdfx}->start_char($line);
        $self->{stage} = 'char'; return;
    }
    if ($keyword eq 'endfont') {
        $self->{stage} = 'eof'; return;
    }
}

sub parse_char_stage_line {
    my ($self, $line, $keyword) = @_;
    if ($keyword eq 'bitmap') {
        $self->{stage} = 'bitmap'; return;
    }
    $self->{bdfx}->set_char_info($line);
}

sub parse_bitmap_stage_line {
    my ($self, $line, $keyword) = @_;
    if ($keyword eq 'endchar') {
        $self->{stage} = 'chars'; return;
    }
    if ($keyword =~ m{^[0-9A-fa-f]+$}) {
        $line->{hex} = $keyword;
        $self->{bdfx}->add_bitmap_data($line);
        return;
    }
}

sub parse_eof_stage_line {
    my ($self, $line, $keyword) = @_;
    $self->eof();
}

sub eof {
    my ($self) = @_;
    return if $self->{eof};
    $self->{eof} = 1;
    $self->{font}->finalize();
}

1;
