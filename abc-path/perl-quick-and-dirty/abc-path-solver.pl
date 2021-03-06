#!/usr/bin/perl

package Games::ABC_Path::Solver::Base;

use strict;
use warnings;

sub new
{
    my $class = shift;

    my $self = bless {}, $class;

    $self->_init(@_);

    return $self;
}

package Games::ABC_Path::Solver::Move;

use strict;
use warnings;

our @ISA = qw(Games::ABC_Path::Solver::Base);

sub get_text
{
    my ($self) = @_;

    return $self->{_text};
}

sub _depth {
    my $self = shift;

    if (@_) {
        $self->{_depth} = shift;
    }

    return $self->{_depth};
}

sub get_depth
{
    my ($self) = @_;

    return $self->_depth();
}

sub _init
{
    my ($self, $args) = @_;

    $self->{_text} = $args->{text};
    $self->_depth($args->{depth} || 0);

    return;
}

sub bump
{
    my ($self) = @_;

    return ref($self)->new(
        {
            text => $self->get_text(),
            depth => ($self->get_depth+1),
        }
    );
}

package Games::ABC_Path::Solver::Board;

use strict;
use warnings;

use Carp;

our @ISA = qw(Games::ABC_Path::Solver::Base);

my $ABCP_VERDICT_NO = 0;
my $ABCP_VERDICT_MAYBE = 1;
my $ABCP_VERDICT_YES = 2;

my $BOARD_LEN = 5;
my $BOARD_LEN_LIM = $BOARD_LEN - 1;

my @letters = (qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y));

my $ABCP_MAX_LETTER = $#letters;

my %letters_map = (map { $letters[$_] => $_ } (0 .. $ABCP_MAX_LETTER));

sub get_letter_numeric
{
    my ($self, $letter_ascii) = @_;

    my $index = $letters_map{$letter_ascii};

    if (!defined ($index))
    {
        confess "Unknown letter '$letter_ascii'";
    }

    return $index;
}

sub _iter_changed {
    my $self = shift;

    if (@_) {
        $self->{_iter_changed} = shift;
    }

    return $self->{_iter_changed};
}

sub _moves {
    my $self = shift;

    if (@_) {
        $self->{_moves} = shift;
    }

    return $self->{_moves};
}

sub _error {
    my $self = shift;

    if (@_) {
        $self->{_error} = shift;
    }

    return $self->{_error};
}


sub _inc_changed {
    my ($self) = @_;

    $self->_iter_changed($self->_iter_changed+1);

    return;
}

sub _flush_changed {
    my ($self) = @_;

    my $ret = $self->_iter_changed;

    $self->_iter_changed(0);

    return $ret;
}

sub _add_move {
    my ($self, $move) = @_;

    push @{$self->_moves()}, $move;

    $self->_inc_changed;

    return;
}

sub get_successful_layouts {
    my ($self) = @_;

    return [@{$self->_successful_layouts}];
}

sub _successful_layouts {
    my $self = shift;

    if (@_) {
        $self->{_successful_layouts} = shift;
    }

    return $self->{_successful_layouts};
}


sub _layout {
    my $self = shift;

    if (@_) {
        $self->{_layout} = shift;
    }

    return $self->{_layout};
}

sub _y_indexes
{
    return (0 .. $BOARD_LEN_LIM);
}

sub _x_indexes
{
    return (0 .. $BOARD_LEN_LIM);
}

# The letter indexes.
sub _l_indexes
{
    return (0 .. $ABCP_MAX_LETTER);
}


sub _init
{
    my ($self, $args) = @_;

    my $layout_string = $args->{layout};

    if (!defined($layout_string))
    {
        $layout_string = '';
    }

    $self->_layout(\$layout_string);
    $self->_successful_layouts([]);
    $self->_moves([]);
    $self->_iter_changed(0);

    return;
}

sub _xy_to_idx
{
    my ($self, $x, $y) = @_;

    if (($x < 0) or ($x > $BOARD_LEN_LIM))
    {
        confess "X $x out of range.";
    }

    if (($y < 0) or ($y > $BOARD_LEN_LIM))
    {
        confess "Y $y out of range.";
    }


    return $y * $BOARD_LEN +$x;
}

sub _calc_offset
{
    my ($self, $letter, $x, $y) = @_;

    if (($letter < 0) or ($letter >= 25))
    {
        confess "Letter $letter out of range.";
    }

    return $letter * ($BOARD_LEN * $BOARD_LEN) + $self->_xy_to_idx($x,$y);
}

sub get_verdict
{
    my ($self, $letter, $x, $y) = @_;

    return vec(${$self->_layout}, $self->_calc_offset($letter, $x, $y), 2);
}

sub set_verdict
{
    my ($self, $letter, $x, $y, $verdict) = @_;

    if (not
        (($verdict == $ABCP_VERDICT_NO)
        || ($verdict == $ABCP_VERDICT_MAYBE)
        || ($verdict == $ABCP_VERDICT_YES))
    )
    {
        confess "Invalid verdict $verdict .";
    }

    vec(${$self->_layout}, $self->_calc_offset($letter,$x,$y), 2)
        = $verdict;

    return;
}

sub xy_loop
{
    my ($self, $sub_ref) = (@_);

    foreach my $y ($self->_y_indexes)
    {
        if ($self->_error())
        {
            return;
        }
        foreach my $x ($self->_x_indexes)
        {
            if ($self->_error())
            {
                return;
            }
            $sub_ref->($x,$y);
        }
    }
    return;
}


sub set_verdicts_for_letter_sets
{
    my ($self, $letter_list, $maybe_list) = @_;

    my %cell_is_maybe =
        (map {; sprintf("%d,%d", @$_) => 1; } @$maybe_list);

    foreach my $letter_ascii (@$letter_list)
    {
        my $letter = $self->get_letter_numeric($letter_ascii);

        $self->xy_loop(
            sub {
                my ($x, $y) = @_;

                $self->set_verdict($letter, $x, $y,
                    ((exists $cell_is_maybe{"$x,$y"})
                        ? $ABCP_VERDICT_MAYBE
                        : $ABCP_VERDICT_NO
                    )
                );
            }
        );
    }

    return;
}

sub set_conclusive_verdict_for_letter
{
    my ($self, $letter, $xy) = @_;

    my ($l_x, $l_y) = @$xy;

    $self->xy_loop(sub {
            my ($x, $y) = @_;

            $self->set_verdict($letter, $x, $y,
                ((($l_x == $x) && ($l_y == $y))
                    ? $ABCP_VERDICT_YES
                    : $ABCP_VERDICT_NO
                )
            );
        }
    );
    OTHER_LETTER:
    foreach my $other_letter ($self->_l_indexes)
    {
        if ($other_letter == $letter)
        {
            next OTHER_LETTER;
        }
        $self->set_verdict($other_letter, $l_x, $l_y, $ABCP_VERDICT_NO);
    }

    return;
}

sub _get_possible_letter_indexes
{
    my ($self, $x, $y) = @_;

    return
    [
        grep { $self->get_verdict($_, $x, $y) != $ABCP_VERDICT_NO }
        $self->_l_indexes()
    ];
}

sub get_possible_letters_for_cell
{
    my ($self, $x, $y) = @_;

    return [@letters[@{$self->_get_possible_letter_indexes($x,$y)}]];
}

sub _get_possible_letters_string
{
    my ($self, $x, $y) = @_;

    return join(',', @{$self->get_possible_letters_for_cell($x,$y)});
}


sub _infer_letters
{
    my ($self) = @_;

    foreach my $letter ($self->_l_indexes)
    {
        my @true_cells;

        $self->xy_loop(sub {
            my @c = @_;

            my $ver = $self->get_verdict($letter, @c);
            if (    ($ver == $ABCP_VERDICT_YES)
                || ($ver == $ABCP_VERDICT_MAYBE))
            {
                push @true_cells, [@c];
            }
        });

        if (! @true_cells)
        {
            $self->_error(['letter', $letter]);
            return;
        }
        elsif (@true_cells == 1)
        {
            my $xy = $true_cells[0];
            if ($self->get_verdict($letter, @$xy) ==
                $ABCP_VERDICT_MAYBE)
            {
                $self->set_conclusive_verdict_for_letter($letter, $xy);
                $self->_add_move(
                    Games::ABC_Path::Solver::Move->new(
                        {
                            text =>  "For $letters[$letter] only ($xy->[0],$xy->[1]) is possible.",
                        }
                    )
                );
            }
        }

        my @neighbourhood = (map { [(0) x $BOARD_LEN] } ($self->_y_indexes));

        foreach my $true (@true_cells)
        {
            foreach my $coords
            (
                grep { $_->[0] >= 0 and $_->[0] < $BOARD_LEN and $_->[1] >= 0 and
                $_->[1] < $BOARD_LEN }
                map { [$true->[0] + $_->[0], $true->[1] + $_->[1]] }
                map { my $d = $_; map { [$_, $d] } (-1 .. 1) }
                (-1 .. 1)
            )
            {
                $neighbourhood[$coords->[1]][$coords->[0]] = 1;
            }
        }

        foreach my $neighbour_letter (
            (($letter > 0) ? ($letter-1) : ()),
            (($letter < $ABCP_MAX_LETTER) ? ($letter+1) : ()),
        )
        {
            $self->xy_loop(sub {
                my ($x, $y) = @_;

                if ($neighbourhood[$y][$x])
                {
                    return;
                }

                my $existing_verdict =
                    $self->get_verdict($neighbour_letter, $x, $y);

                if ($existing_verdict == $ABCP_VERDICT_YES)
                {
                    $self->_error(['mismatched_verdict', $x, $y]);
                    return;
                }

                if ($existing_verdict == $ABCP_VERDICT_MAYBE)
                {
                    $self->set_verdict($neighbour_letter, $x, $y, $ABCP_VERDICT_NO);
                    $self->_add_move(
                        Games::ABC_Path::Solver::Move->new(
                            {
                                text => "$letters[$neighbour_letter] cannot be at ($x,$y) due to lack of vicinity from $letters[$letter].",
                            }
                        )
                    );
                }
            });
        }
    }

    return;
}

sub _infer_cells
{
    my ($self) = @_;

    $self->xy_loop(sub {
        my ($x, $y) = @_;

        my $letters_aref = $self->_get_possible_letter_indexes($x, $y);

        if (! @$letters_aref)
        {
            $self->_error(['cell', [$x, $y]]);
            return;
        }
        elsif (@$letters_aref == 1)
        {
            my $letter = $letters_aref->[0];

            if ($self->get_verdict($letter, $x, $y) == $ABCP_VERDICT_MAYBE)
            {
                $self->set_conclusive_verdict_for_letter($letter, [$x, $y]);
                $self->_add_move(
                    Games::ABC_Path::Solver::Move->new(
                        {
                            text => "The only letter that can be at ($x,$y) is $letters[$letter]. Invalidating it for all other cells."
                        }
                    )
                );
            }
        }
    });

    return;
}


sub _inference_iteration
{
    my ($self) = @_;

    $self->_infer_letters;

    $self->_infer_cells;

    return $self->_flush_changed;
}

sub _neighbourhood_and_individuality_inferring
{
    my ($self) = @_;

    my $num_changed = 0;

    while (my $iter_changed = $self->_inference_iteration())
    {
        if ($self->_error())
        {
            return;
        }
        $num_changed += $iter_changed;
    }

    return $num_changed;
}

sub _clone
{
    my ($self) = @_;

    return
        ref($self)->new(
            {
                layout => ${$self->_layout()},
            }
        );
}

sub solve
{
    my ($self) = @_;

    $self->_neighbourhood_and_individuality_inferring;

    if ($self->_error)
    {
        return $self->_error;
    }

    my @min_coords;
    my @min_options;

    $self->xy_loop(sub {
        my ($x, $y) = @_;

        my $letters_aref = $self->_get_possible_letter_indexes($x, $y);

        if (! @$letters_aref)
        {
            $self->_error(['cell', [$x, $y]]);
        }
        elsif (@$letters_aref > 1)
        {
            if ((!@min_coords) or (@$letters_aref < @min_options))
            {
                @min_options = @$letters_aref;
                @min_coords = ($x,$y);
            }
        }

        return;
    });

    if ($self->_error)
    {
        return $self->_error;
    }

    if (@min_coords)
    {
        my ($x, $y) = @min_coords;
        # We have at least one multiple rank cell. Let's recurse there:
        foreach my $letter (@min_options)
        {
            my $recurse_solver = $self->_clone;

            $self->_add_move(
                Games::ABC_Path::Solver::Move->new(
                {
                    text => "We have non-conclusive cells. Trying $letters[$letter] for ($x,$y)",
                }
            ),
            );

            $recurse_solver->set_conclusive_verdict_for_letter(
                $letter, [$x,$y]
            );

            $recurse_solver->solve;

            foreach my $move (@{ $recurse_solver->get_moves })
            {
                $self->_add_move($move->bump());
            }

            if ($recurse_solver->_error())
            {
                $self->_add_move(
                    Games::ABC_Path::Solver::Move->new(
                    {
                        text => "Trying $letters[$letter] for ($x,$y) results in an error.",
                    }
                    )
                );
            }
            else
            {
                $self->_add_move(
                    Games::ABC_Path::Solver::Move->new(
                        {
                            text => "Trying $letters[$letter] for ($x,$y) returns a success."
                        }
                    )
                );
                push @{$self->_successful_layouts},
                    @{$recurse_solver->get_successful_layouts()};
            }
        }

        my $count = @{$self->_successful_layouts()};
        if (! $count)
        {
            return ['all_options_bad'];
        }
        elsif ($count == 1)
        {
            return ['success'];
        }
        else
        {
            return ['success_multiple'];
        }
    }
    else
    {
        $self->_successful_layouts([$self->_clone()]);
        return ['success'];
    }
}

my $letter_re_s = join('', map { quotemeta($_) } @letters);
my $letter_re = qr{[$letter_re_s]};
my $letter_and_space_re = qr{[ $letter_re_s]};
my $top_bottom_re = qr/^${letter_re}{7}\n/ms;
my $inner_re = qr/^${letter_re}${letter_and_space_re}{5}${letter_re}\n/ms;

sub _assert_letters_appear_once
{
    my ($self, $layout_string) = @_;

    my %count_letters = (map { $_ => 0 } @letters);
    foreach my $letter ($layout_string =~ m{($letter_re)}g)
    {
        if ($count_letters{$letter}++)
        {
            confess "Letter '$letter' encountered twice in the layout.";
        }
    }

    return;
}

sub _process_major_diagonal
{
    my ($self, $args) = @_;

    my @major_diagonal_letters;

    $args->{top} =~ m{\A($letter_re)};

    push @major_diagonal_letters, $1;

    $args->{bottom} =~ m{($letter_re)\z};

    push @major_diagonal_letters, $1;

    $self->set_verdicts_for_letter_sets(
        \@major_diagonal_letters,
        [map { [$_,$_] } $self->_y_indexes],
    );

    return;
}

sub _process_minor_diagonal
{
    my ($self, $args) = @_;

    my @minor_diagonal_letters;

    $args->{top} =~ m{($letter_re)\z};

    push @minor_diagonal_letters, $1;

    $args->{bottom} =~ m{\A($letter_re)};

    push @minor_diagonal_letters, $1;

    $self->set_verdicts_for_letter_sets(
        \@minor_diagonal_letters,
        [map { [$_, 4-$_] } ($self->_y_indexes)]
    );

    return;
}

sub _process_input_columns
{
    my ($self, $args) = @_;

    my $top_row = $args->{top};
    my $bottom_row = $args->{bottom};

    foreach my $x ($self->_x_indexes)
    {
        $self->set_verdicts_for_letter_sets(
            [substr($top_row, $x+1, 1), substr($bottom_row, $x+1, 1),],
            [map { [$x,$_] } $self->_y_indexes],
        );
    }

    return;
}

sub _process_input_rows_and_initial_letter_clue
{
    my ($self, $args) = @_;

    my $rows = $args->{rows};

    my ($clue_x, $clue_y, $clue_letter);

    foreach my $y ($self->_y_indexes)
    {
        my $row = $rows->[$y];
        $self->set_verdicts_for_letter_sets(
            [substr($row, 0, 1), substr($row, -1),],
            [map { [$_,$y] } $self->_x_indexes],
        );

        my $s = substr($row, 1, -1);
        if ($s =~ m{($letter_re)}g)
        {
            my ($l, $x_plus_1) = ($1, pos($s));
            if (defined($clue_letter))
            {
                confess "Found more than one clue letter in the layout!";
            }
            ($clue_x, $clue_y, $clue_letter) = ($x_plus_1-1, $y, $l);
        }
    }

    if (!defined ($clue_letter))
    {
        confess "Did not find any clue letters inside the layout.";
    }

    $self->set_conclusive_verdict_for_letter(
        $self->get_letter_numeric($clue_letter),
        [$clue_x, $clue_y],
    );

    return;
}

sub input
{
    my ($self, $args) = @_;

    if ($args->{version} ne 1)
    {
        die "Can only handle version 1";
    }

    my $layout_string = $args->{layout};
    if ($layout_string !~ m/\A${top_bottom_re}${inner_re}{5}${top_bottom_re}\z/ms)
    {
        die "Invalid format. Should be Letter{7}\n(Letter{spaces or one letter}{5}Letter){5}\nLetter{7}";
    }

    my @rows = split(/\n/, $layout_string);

    my $top_row = shift(@rows);
    my $bottom_row = pop(@rows);

    # Now let's process the layout string and populate the verdicts table.
    $self->_assert_letters_appear_once($layout_string);

    my $parse_context =
        { top => $top_row, bottom => $bottom_row, rows => \@rows, }
        ;

    $self->_process_major_diagonal($parse_context);

    $self->_process_minor_diagonal($parse_context);

    $self->_process_input_columns($parse_context);

    $self->_process_input_rows_and_initial_letter_clue($parse_context);


    return;
}

sub _get_results_text_table
{
    my ($self) = @_;

    require Text::Table;

    my $tb =
        Text::Table->new(
            \" | ", (map {; "X = $_", (\' | '); } $self->_x_indexes)
        );

    foreach my $y ($self->_y_indexes)
    {
        $tb->add(
            map
            { $self->_get_possible_letters_string($_, $y) }
            $self->_x_indexes
        );
    }

    return $tb;
}

sub get_successes_text_tables
{
    my ($self) = @_;

    return [map { $_->_get_results_text_table() } @{$self->get_successful_layouts()}];
}

# Input the board.

sub input_from_file
{
    my ($class, $board_fn) = @_;

    my $self = $class->new;

    open my $in_fh, "<", $board_fn
        or die "Cannot open '$board_fn' - $!";

    my $first_line = <$in_fh>;
    chomp($first_line);

    my $magic = 'ABC Path Solver Layout Version 1:';
    if ($first_line !~ m{\A\Q$magic\E\s*\z})
    {
        die "Can only process files whose first line is '$magic'!";
    }

    my $layout_string = '';
    foreach my $line_idx (1 .. 7)
    {
        chomp(my $line = <$in_fh>);
        $layout_string .= "$line\n";
    }
    close($in_fh);

    $self->input({ layout => $layout_string, version => 1});

    return $self;
}

sub get_moves
{
    my ($self) = @_;

    return [@{ $self->_moves }];
}

package main;

use strict;
use warnings;

# my $solver = Games::ABC_Path::Solver::Board->new;

my $board_fn = shift(@ARGV);

if (!defined ($board_fn))
{
    die "Filename not specified - usage: abc-path-solver.pl [filename]!";
}

my $solver = Games::ABC_Path::Solver::Board->input_from_file($board_fn);
# Now let's do a neighbourhood inferring of the board.

$solver->solve;

foreach my $move (@{$solver->get_moves})
{
    print +(' => ' x $move->get_depth()), $move->get_text(), "\n";
}

print map { my $s = $_; $s =~ s/ +$//gms; $s } @{$solver->get_successes_text_tables};

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 Shlomi Fish

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=head1 LICENSING EXPLANATION

This is the MIT/X11 Licence. For more information see:

1. L<http://www.opensource.org/licenses/mit-license.php>

2. L<http://en.wikipedia.org/wiki/MIT_License>

=cut
