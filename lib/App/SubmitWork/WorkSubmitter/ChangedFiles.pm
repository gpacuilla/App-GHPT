package App::SubmitWork::WorkSubmitter::ChangedFiles;

use App::SubmitWork::Wrapper::OurMoose;

use List::Util qw( any uniq );
use App::SubmitWork::Types qw( ArrayRef HashRef Str );

=head1 SYNOPSIS

    # print out all modified / addded file in this branch
    say for $changed_files->changed_files->@*;

=head1 DESCRIPTION

A class that represents what files were added, modified or deleted in a
branch, as well as what files exist in the branch.

Normally constructed by L<App::SubmitWork::WorkSubmitter::ChangedFilesFactory>.

=attribute added_files

All files added in this branch.

Arrayref of String. Required.

=attribute modified_files

All files modified in this branch (excluding those that were added in this
branch)

Arrayref of String. Required.

=attribute deleted_files

All files deleted in this branch.

Arrayref of String. Required.

=attribute all_Files

All files in this branch (including those created before the branch was
branched.)  i.e. every file that you'd get from a fresh checkout of this
branch.

Arrayref of String. Required.

=cut

has [
    qw(
        added_files
        all_files
        deleted_files
        modified_files
        )
    ] => (
    is       => 'ro',
    isa      => ArrayRef [Str],
    required => 1,
    );

has _file_exists_hash => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    builder => '_build_file_exists_hash',
);

sub _build_file_exists_hash ($self) {
    return +{ map { $_ => 1 } $self->all_files->@* };
}

=head2 Methods

=method changed_files

All changed files (i.e. all files that were either added or modified in
this branch.)  Returns Arrayref of Strings.

=cut

sub changed_files ($self) {
    return [ uniq sort $self->added_files->@*, $self->modified_files->@* ];
}

=method changed_files_match( $regex )

Returns true iff any of the changed files filenames match the passed regex

=cut

sub changed_files_match ( $self, $regex ) {
    return any { $_ =~ $regex } $self->changed_files->@*;
}

=method changed_files_matching( $regex )

Returns a list of changed files filenames matching the passed regex

=cut

sub changed_files_matching ( $self, $regex ) {
    return grep { $_ =~ $regex } $self->changed_files->@*;
}

=method file_exists( $path )

Does the passed file exist on the branch (i.e. if you were to do a fresh
checkout of this branch would the file be present)

=cut

sub file_exists ( $self, $path ) {
    return $self->_file_exists_hash->{$path};
}

=method file_status( $path )

Returns the file status.  This is either C<A> (added), C<D> (deleted), C<M>
(modified), C< > (exists, not modified) or undef (doesn't exist).

=cut

# this is inefficently written, but it shouldn't really make any difference
# for the number of files we're talking about here
sub file_status ( $self, $path ) {
    return 'A' if any { $_ eq $path } $self->added_files->@*;
    return 'M' if any { $_ eq $path } $self->modified_files->@*;
    return 'D' if any { $_ eq $path } $self->deleted_files->@*;
    return q{ } if $self->file_exists($path);
    return undef;
}

__PACKAGE__->meta->make_immutable;
1;
