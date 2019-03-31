package Games::ABC_Path::MicrosoftRand;

use 5.006;
use strict;
use warnings;

=head1 NAME

Games::ABC_Path::MicrosoftRand - a pseudo-random number generator compatible
with Visual C.

=head1 SYNOPSIS

    use Games::ABC_Path::MicrosoftRand;

    my $randomizer = Games::ABC_Path::MicrosoftRand->new(seed => 24);

    my $random_digit = $randomizer->rand_max(10);

=head1 DESCRIPTION

This is a random number generator used by Games::ABC_Path::Generator, which
emulates the one found in Microsoft's Visual C++. It was utilised here, out
of familiarity and accessibility, because it is commonly used to generate
Freecell layouts in the Freecell world (see
L<http://en.wikipedia.org/wiki/FreeCell_%28Windows%29> ).

=cut

use integer;

use Class::XSAccessor {
    constructor => 'new',
    accessors   => [qw(seed)],
};

sub rand
{
    my $self = shift;
    $self->seed( ( $self->seed() * 214013 + 2531011 ) & (0x7FFF_FFFF) );
    return ( ( $self->seed >> 16 ) & 0x7fff );
}

sub max_rand
{
    my ( $self, $max ) = @_;

    return ( $self->rand() % $max );
}

sub shuffle
{
    my ( $self, $deck ) = @_;

    if (@$deck)
    {
        my $i = @$deck;
        while ( --$i )
        {
            my $j = $self->max_rand( $i + 1 );
            @$deck[ $i, $j ] = @$deck[ $j, $i ];
        }
    }

    return $deck;
}

=head1 SUBROUTINES/METHODS

=head2 new

The constructor. Accepts a numeric seed as an argument.

    my $randomizer = Games::ABC_Path::MicrosoftRand->new(seed => 1);

=head2 $randomizer->rand()

Returns a random integer from 0 up to 0x7fff - 1.

    my $n = $randomizer->rand()

=head2 $randomizer->max_rand($max)

Returns a random integer in the range 0 to ($max-1).

    my $n = $randomizer->max_rand($max);
    # $n is now between 0 and $max - 1.

=head2 $randomizer->seed($seed)

Can be used to re-assign the seed of the randomizer (though not recommended).

=head2 my $array_ref = $randomizer->shuffle(\@array)

Shuffles the array reference of the first argument, B<destroys it> and returns
it. This is using the fisher-yates shuffle.

=cut

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-abc_path-generator at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-ABC_Path-Generator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::ABC_Path::MicrosoftRand


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-ABC_Path-Generator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-ABC_Path-Generator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-ABC_Path-Generator>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-ABC_Path-Generator/>

=back

=cut

1;    # End of Games::ABC_Path::MicrosoftRand
