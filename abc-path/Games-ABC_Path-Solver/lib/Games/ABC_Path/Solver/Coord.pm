package Games::ABC_Path::Solver::Coord;

use warnings;
use strict;

use parent 'Games::ABC_Path::Solver::Base';

=head1 NAME

Games::ABC_Path::Solver::Coord - X/Y coordinate class for the ABC Path classes.

=head1 SYNOPSIS

    use parent 'Games::ABC_Path::Solver::Base';

    sub _init
    {

    }

=head1 FUNCTIONS

=cut

use integer;

=head2 $coord->x()

B<For internal use>.

=cut

sub x
{
    my $self = shift;

    if (@_)
    {
        $self->{x} = shift;
    }

    return $self->{x};
}

=head2 $coord->y()

B<For internal use>.

=cut

sub y
{
    my $self = shift;

    if (@_)
    {
        $self->{'y'} = shift;
    }

    return $self->{'y'};
}

sub _to_s
{
    my $self = shift;

    return sprintf( "%d,%d", $self->x, $self->y );
}

sub _init
{
    my ( $self, $args ) = @_;

    $self->x( $args->{x} );
    $self->y( $args->{'y'} );

    return;
}

sub _equal
{
    my ( $self, $other_xy ) = @_;

    return ( ( $self->x == $other_xy->x ) && ( $self->y == $other_xy->y ) );
}

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-abc_path-solver at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-ABC_Path-Solver>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::ABC_Path::Solver::Coord


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-ABC_Path-Solver>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-ABC_Path-Solver>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-ABC_Path-Solver>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-ABC_Path-Solver/>

=back

=cut

1;    # End of Games::ABC_Path::Solver::Base
