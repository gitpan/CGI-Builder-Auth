package CGI::Builder::Auth

# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use 5.006001
; use strict

; our $VERSION = '0.03'

; use CGI::Builder::Auth::Context

; use Object::props
(	{ name => 'auth'
	, default => sub { CGI::Builder::Auth::Context->new( owner => $_[0]) }
	}
)

; sub auth_config
	{ my ($self) = shift
	; CGI::Builder::Auth::Context->config(@_)
	}
; sub auth_user_config
	{ my ($self) = shift
	; CGI::Builder::Auth::Context->User_factory->config(@_)
	}
; sub auth_group_config
	{ my ($self) = shift
	; CGI::Builder::Auth::Context->Group_factory->config(@_)
	}

; sub OH_cleanup 
	{ my ($self) = @_
	# Prevent memory leaks in mod_perl by removing circular refs.
	; if (defined $self->{auth})
		{ defined($self->auth->{owner})   && $self->auth->owner(undef)
		; defined($self->auth->{session}) && $self->auth->session(undef)
		}
	}

"Copyright 2004 Vincent Veselosky [[http://control-escape.com]]";

__END__

=head1 NAME

CGI::Builder::Auth - Add user authentication to the CGI::Builder Framework

=head1 SYNOPSIS

  # Recommended: Include CGI::Builder::Session BEFORE CGI::Builder::Auth
  use CGI::Builder qw/ CGI::Builder::Session CGI::Builder::Auth /;
  
  # 'protected' page available only to authenticated (logged in) users
  sub SH_protected {
    my ($app) = @_;
    $app->auth->require_valid_user or return $app->switch_to('login');
  }
  
  # 'admin' page available only to members of 'administrators' group
  sub SH_admin {
    my ($app) = @_;
    $app->auth->require_group('administrators') 
      or return $app->switch_to('forbidden');
  }
  
  # 'private' page available only to select users
  sub SH_private {
    my ($app) = @_;
    $app->auth->require_user(qw/ bob carol ted alice /) 
      or return $app->switch_to('forbidden');
  }
  

=head1 ABSTRACT

Adds user authentication and authorization to the CGI::Builder Framework.

=head1 DESCRIPTION

For those who prefer to read code rather than documentation, see the examples
directory in the distribution. The example is well commented and exercises the
API fully.

CGI::Builder::Auth adds an authentication system to the CBF. A "context" is
encapsulated in an object stored in the C<auth> property. It keeps track of the
current user, and provides methods for performing common tests to
determine that user's status in the current context.

The module includes simple user/group database access, with the database stored
in plain text files. The files should be compatible with Apache password files
generated by the C<htpasswd> utility, but this feature is untested as of
release 0.01. Future versions will include support for user/group information
stored in SQL databases, and will provide a mechanism allowing developers to
plug in their own databases.

This module can use L<CGI::Builder::Session|CGI::Builder::Session> to track the
authentication context from one request to the next, so a user can login once
and remain logged in until her session terminates. This happens automatically
when the module detects that you are using sessions. You don't need to do
anything special. The module will function without sessions, but only within
the current request. Realistically, for any real web application you will want
to use the session integration.

Any session keys set by this module will begin with 'CBA_'. Do not attempt to
access these keys directly, they are intended for internal use only. 

=head1 APPLICATION PROGRAMMING INTERFACE

This module adds the following methods to the CBF.

=head2 C<auth>

The authentication context object. Its API is documented separately in
L<CGI::Builder::Auth::Context>.

=head2 C<auth_user_config>

A group accessor (like the C<param> property). Supported configuration options:

=over

=item * B<DB>

The complete path to your user database file. Default is C<./.htpasswd>.  This
file must be writable by your web server! Insufficient file permission is the
most common support problem, so please check this before sending mail to the
list for support.

=item * B<Encrypt>

How to disguise the password in the database. One of 'crypt' or 'MD5'. For
compatibility with Apache htpasswd files, you probably want 'crypt'. Default
is 'crypt'.
  
  $app->auth_user_config(DB => './.htpasswd', Encrypt => 'crypt');
  

=back

=head2 C<auth_group_config>

A group accessor (like the C<param> property). Supported configuration options:

=over

=item * B<DB>

The complete path to your group database file. Default is C<./.htgroup>.  This
file must be writable by your web server! Insufficient file permission is the
most common support problem, so please check this before sending mail to the
list for support.
  
  $app->auth_group_config(DB => './.htgroup'');
  

=back

=head2 C<auth_config>

A group accessor (like the C<param> property). Supported configuration options:

=over

=item * B<magic_string>

The C<magic_string> is used to verify the authentication token that is
retrieved from the session. It should be set to something unique for your
application. It I<must> be set before the first use of the C<auth> object,
and I<must not> be changed during the execution of your program.

=item * B<User_factory> (advanced)

This configuration parameter is for advanced users who wish to supply their own
custom class for user objects. See L<"Custom User and Group Classes"> below.

=item * B<Group_factory> (advanced)

This configuration parameter is for advanced users who wish to supply their own
custom class for group objects. See L<"Custom User and Group Classes"> below.

=back


=head1 TROUBLESHOOTING

If C<make test> works for you but your application does not work as you expect,
please check the following things before sending email to the mailing list for
support.

=over

=item * Set DB in OH_init

Ensure you have set the DB configuration option for users and groups in your
code B<before> the first use of the C<auth> property.

=item * Set File Permissions!

Ensure that the DB files are B<writable> by your web server. On many systems
the web server runs as a special user, which might be called 'apache', 'www',
or 'nobody'. This user B<must> be able to read and write your DB files. You may
have to C<chmod 777 filename> to get this to work. THIS IS THE MOST COMMON
PROBLEM.

=item * Set Directory Permissions

Ensure that the DB files actually exist after running your program. Your web
server will need write access to the directory in order to create them. If it
cannot, you may have to create them manually using C<touch filename>, and then
set permissions appropriately.

=item * Configure Session First

Ensure that you have set the configuration options for CGI::Builder::Session in
your code B<before> the first use of the C<auth> property.

=back



=head1 Custom User and Group Classes

WARNING: This is an experimental feature.

It may happen that you have your user information stored in a relational
database, and you would like to access additional columns in the user table, or
perform special queries on related tables. This module can work together with
custom classes that you create to implement this additional functionality.

Your custom user class I<must> implement the interface described in
L<CGI::Builder::Auth::User>, and your custom group class I<must> implement the
interface described in L<CGI::Builder::Auth::Group>. They may of course have
many other properties and methods, but all the ones described in these resources
I<must> be supported.

However, your custom classes should I<not> inherit from these default classes. The
default classes are designed to work specifically with the text file format and
do not contain any reusable methods for SQL databases.

Custom classes come as a matched set. If you use a custom user class, you must
also use a custom group class.

To instruct the C<auth> object to use your custom classes, set the
C<User_factory> and C<Group_factory> auth_config parameters to the appropriate class
names in your OH_init. The configurator will attempt to C<require> these
modules at the time you set the values. If they cannot be found, the system
will ignore your custom classes and use the defaults. This behavior may change
in a future release, feedback is welcome.


=head1 TO DO

=over

=item * Test Integration

Make the test suite actually test the CGI::Builder integration!

=item * Test Error Conditions

Make the test suite test for behavior under common error conditions such as
unwritable database files. Behavior for most errors is currently undefined.

=item * Refine Object Model

Define the API for the user and group objects and their factories. This step is
necessary to support pluggable user databases.

=item * Support SQL Databases

Add support for storing user/group data in SQL databases.

=item * Ongoing Refactor

Refactor the backend to better support the Factory design pattern, and clean
out some of the old User-Manage code that is no longer needed.

=back

=head1 SEE ALSO

=over

=item 

L<CGI::Builder::Auth::Context>

=item 

L<CGI::Builder>

=item 

L<CGI::Session>

=back

=head1 SUPPORT

Support for this module and all the modules of the CBF is via the mailing list.
The list is used for general support on the use of the CBF, announcements, bug
reports, patches, suggestions for improvements or new features. The API to the
CBF is stable, but if you use the CBF in a production environment, it's
probably a good idea to keep a watch on the list.

You can join the CBF mailing list at this url:

L<http://lists.sourceforge.net/lists/listinfo/cgi-builder-users>


=head1 AUTHOR

Vincent Veselosky

=head1 CREDITS

Large portions of the code are borrowed from the HTTPD-User-Manage collection by
Doug MacEachern and Lincoln Stein.

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Vincent Veselosky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
