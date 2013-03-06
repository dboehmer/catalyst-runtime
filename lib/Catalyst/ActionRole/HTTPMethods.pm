package Catalyst::ActionRole::HTTPMethods;

use Moose::Role;

requires 'match', 'match_captures', 'list_extra_info';

around ['match','match_captures'] => sub {
  my ($orig, $self, $ctx, @args) = @_;
  my $expected = $self->_normalize_expected_http_method($ctx->req);
  return $self->_has_expected_http_method($expected) ?
    $self->$orig($ctx, @args) :
    0;
};

sub _normalize_expected_http_method {
  my ($self, $req) = @_;
  return $req->header('X-HTTP-Method') ||
    $req->header('X-HTTP-Method-Override') ||
    $req->header('X-METHOD-OVERRIDE') ||
    $req->header('x-tunneled-method') ||
    $req->method;
}

sub _has_expected_http_method {
  my ($self, $expected) = @_;
  return 1 unless scalar(my @allowed = $self->allowed_http_methods);
  return scalar(grep { lc($_) eq lc($expected) } @allowed) ?
    1 : 0;
}

sub allowed_http_methods { @{shift->attributes->{Method}||[]} }

around 'list_extra_info' => sub {
  my ($orig, $self, @args) = @_;
  return {
    %{ $self->$orig(@args) }, 
    HTTP_METHODS => [sort $self->allowed_http_methods],
  };
};

1;

=head1 NAME

Catalyst::ActionRole::HTTPMethods - Match on HTTP Methods

=head1 SYNOPSIS

    package MyApp::Web::Controller::MyController;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    sub user_base : Chained('/') CaptureArg(0) { ... }

      sub get_user    : Chained('user_base') Args(1) GET { ... }
      sub post_user   : Chained('user_base') Args(1) POST { ... }
      sub put_user    : Chained('user_base') Args(1) PUT { ... }
      sub delete_user : Chained('user_base') Args(1) DELETE { ... }
      sub head_user   : Chained('user_base') Args(1) HEAD { ... }
      sub option_user : Chained('user_base') Args(1) OPTION { ... }
      sub option_user : Chained('user_base') Args(1) PATCH { ... }


      sub post_and_put : Chained('user_base') POST PUT Args(1) { ... }
      sub method_attr  : Chained('user_base') Method('DELETE') Args(0) { ... }

    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

This is an action role that lets your L<Catalyst::Action> match on standard
HTTP methods, such as GET, POST, etc.

Since most web browsers have limited support for rich HTTP Method vocabularies
we also support setting the expected match method via the follow non standard
but widely used http extensions.  Our support for these should not be taken as
an endorsement of the technique.   Rt is merely a reflection of our desire to
work well with existing systems and common client side tools.

=over 4

=item X-HTTP-Method (Microsoft)

=item X-HTTP-Method-Override (Google/GData)

=item X-METHOD-OVERRIDE (IBM)

=item x-tunneled-method (used in many other similar systems on CPAN

=back 

Please note the insanity of overriding a GET request with a DELETE override...
Rational practices suggest that using POST with overrides to emulate PUT and
DELETE can be an acceptable way to deal with client limitations and security
rules on your proxy server. I recommend going no further.

=head1 REQUIRES

This role requires the following methods in the consuming class.

=head2 match

=head2 match_captures

Returns 1 if the action matches the existing request and zero if not.

=head1 METHODS

This role defines the following methods

=head2 match

=head2 match_captures

Around method modifier that return 1 if the request method matches one of the
allowed methods (see L</http_methods>) and zero otherwise.

=head2 allowed_http_methods

An array of strings that are the allowed http methods for matching this action
normalized as noted above (using X-Method* overrides).

=head2 list_extra_info

Adds a key => [@values] "HTTP_METHODS" whose value is an ArrayRef of sorted
allowed methods to the ->list_extra_info HashRef.  This is used primarily for
debugging output.

=head2 _has_expected_http_method ($expected)

Private method which returns 1 if C<$expected> matches one of the allowed
in L</http_methods> and zero otherwise.

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
