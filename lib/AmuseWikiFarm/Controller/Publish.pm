package AmuseWikiFarm::Controller::Publish;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Publish - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller for publishing texts.

=head1 METHODS

=head2 auto

Depending on the site mode, deny access to humans.

=cut

sub auto :Private {
    my ($self, $c) = @_;
    my $site = $c->stash->{site};
    if ($c->user_exists) {
        return 1;
    }
    elsif ($site->human_can_publish) {
        if ($c->session->{i_am_human}) {
            return 1;
        }
        else {
            $c->session(redirect_after_login => $c->request->path);
            $c->response->redirect($c->uri_for('/human'));
            return;
        }
    }
    else {
        $c->session(redirect_after_login => $c->request->path);
        $c->response->redirect($c->uri_for('/login'));
        return;
    }
}


=head2 root

Stash the available revisions, depending on the site mode.

=cut

sub root :Chained('/') :PathPart('publish') :CaptureArgs(0) {
    my ($self, $c) = @_;
    my $site = $c->stash->{site};

    my $search = {};
    # if it's a librarian, we show all the pending revisions
    # while human can see only their own
    unless ($c->user_exists) {
        $search->{session_id} = $c->sessionid;
    }
    my $revs = $site->revisions->search($search,
                                        { order_by => { -desc => 'updated' } });
    $c->stash(revisions => $revs);
}

=head2 pending

Show the revisions not marked as pending

=head2 all

Show all revisions.

=cut

sub pending :Chained('root') :PathPart('pending') :Args(0) {
    my ($self, $c) = @_;
    my $revisions = delete $c->stash->{revisions};
    my $revs = $revisions->search({ status => { '!=' => 'published' } });
    $c->stash(page_title => $c->loc('Pending revisions'));
    $c->stash(revisions => $revs);
};

sub all :Chained('root') :PathPart('all') :Args(0) {
    my ($self, $c) = @_;
    $c->stash(page_title => $c->loc('All revisions'));
    $c->stash(template => 'publish/pending.tt');
}


=head2 publish

Method to publish the texts.

=cut

sub publish :Chained('root') :PathPart('publish') :Args(0) {
    my ($self, $c) = @_;
    # ask for the param
    if (my $revid = $c->request->params->{publish}) {
        $c->log->debug("Found publish parameter, validating");

        # revisions should be already stashed
        if (my $revs = $c->stash->{revisions}) {
            $c->log->debug("Found revision in stash");

            # search that revision id
            if (my $found = $revs->find($revid)) {
                $c->log->debug("Found $revid!");

                # found and pending? publish!
                if ($found && $found->pending) {
                    $c->log->debug("$revid is pending, processing!");
                    my $job = $c->stash->{site}->jobs->publish_add($found);
                    $c->res->redirect($c->uri_for_action('/tasks/display',
                                                         [$job->id]));
                    return;
                }
            }
        }
    }
    $c->flash(error_msg => "Bad revision!");
    $c->res->redirect($c->uri_for_action('/publish/pending'));
}


=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
