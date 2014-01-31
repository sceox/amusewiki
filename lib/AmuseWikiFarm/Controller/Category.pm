package AmuseWikiFarm::Controller::Category;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Category - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    $c->response->body('Matched AmuseWikiFarm::Controller::Category in Category.');
}

=head2 Category listing

=head3 authors

The list of authors

=head3 authors/<name>

Details about the author <name>

=head3 topics

The list of topics

=head3 topics/<name>

=cut

sub authors :Global :Args(0) {
    my ( $self, $c ) = @_;

    $c->detach(category_listing => [ 'author' ]);
}

sub author :Path('/authors') :Args(1) {
    my ( $self, $c, $arg ) = @_;

    $c->detach(category_details => [ author => $arg ]);
}

sub topics :Global :Args(0) {
    my ( $self, $c ) = @_;

    $c->detach(category_listing => [ 'topic' ]);
}

sub topic :Path('/topics') :Args(1) {
    my ( $self, $c, $arg ) = @_;

    $c->detach(category_details => [ topic => $arg ]);
}

sub category_details :Private {
    my ( $self, $c, $type, $name ) = @_;
    my $locale = $c->stash->{locale};
    my $id = $c->stash->{site_id};
    $c->stash(baseurl => $c->uri_for_action('/library/index'));
    my $cat = $c->model('DB::Category')->single({
                                                 site_id => $id,
                                                 type => $type,
                                                 uri  => $name,
                                                });
    # not found unless $cat;
    return unless $cat;
    my $list = $c->model('DB::Category')->list_titles($cat->id, $locale);
    $c->stash(
              template => 'category-details.tt',
              category => $cat,
              list => $list
             );
}

sub category_listing :Private {
    my ( $self, $c, $type ) = @_;
    my $loc = $c->stash->{locale};
    my $id = $c->stash->{site_id};
    my $list = $c->model('DB::Category')->listing($id, $type, $loc);
    $c->stash(
              list => $list,
              template => 'category.tt',
              baseurl => $c->uri_for_action("/category/$type"),
             );
}


=encoding utf8

=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
