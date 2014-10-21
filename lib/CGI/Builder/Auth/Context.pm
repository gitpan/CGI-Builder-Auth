package CGI::Builder::Auth::Context

# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use strict
; use File::Spec

; use Class::constr { init => [ qw/ load_token / ] }

; use Class::props 
	(	{ name => 'User_factory'
		, default => 'CGI::Builder::Auth::User'
		, validation => \&load_factory
		}
	,	{ name => 'Group_factory'
		, default => 'CGI::Builder::Auth::Group'
		, validation => \&load_factory
		}
	)
; use Object::props
	( 	{ name => 'user'
		, default => sub { $_[0]->User_factory->anonymous }
		}
	,	{ name => 'realm'
		, default => 'main'
		}
	,	{ name => 'owner'
		}
	,	{ name => 'session'
		, default => sub 
			{ ref($_[0]->owner) && $_[0]->owner->can('cs')
				? $_[0]->owner->cs
				: undef
			}
		}
	)
; use Class::groups
	( 	{ name => 'config'
		, props => 
			[ 	{ name => 'magic_string'
				, default => 'This is the default magic string, change it to 
					something unique for your application'
				}
			]
		}
	)
	
; sub user_list { $_[0]->User_factory->list }
; sub group_list { $_[0]->Group_factory->list }

; sub add_user { shift()->User_factory->add(@_) }
; sub add_group { shift()->Group_factory->add(@_) }

; sub delete_user { shift()->User_factory->delete(@_) }
; sub delete_group { shift()->Group_factory->delete(@_) }

; sub add_member { shift()->Group_factory->add_member(@_) }
; sub remove_member { shift()->Group_factory->remove_member(@_) }
; sub group_members { shift()->Group_factory->member_list(@_) }

; sub login
	{ my ($self,$username,$pass) = @_
	; my $user = $self->User_factory->new(id => $username) or return
	; if ($user->password_matches($pass) )
		{ $self->user($user)
		; if ( $self->session ) 
			{ $self->session->param('CBA_Token', 
					$self->mk_token($username,$self->session->id) )
			}
		; return $user
		} else {
		; return
		}
	}

; sub logout 
	{ my ($self) = @_
	; if ($self->session) { $self->session->clear(['CBA_Token']) }
	; $self->user( $self->User_factory->anonymous )
	}

; sub require_valid_user { $_[0]->user->exists and $_[0]->user->id ne 'anonymous' }

; sub require_user 
	{ my ($self, @users) = @_
	; my $match = 0
	; for (@users) { $match++,last if $self->user->id eq $_ }
	; return $match
	}

; sub require_group
	{ my ($self, @groups) = @_
	; my $match = 0
	; GROUP: for my $g (@groups) 
		{ for ( $self->Group_factory->member_list($g) ) 
			{ $match++,last GROUP if $_ eq $self->user->id 
			}
		}
	; return $match
	}


; sub mk_token
	{ my ($self,$user,$sid) = @_;
	; require Digest::MD5
	; my $time = time
	; my $hash = Digest::MD5::md5_hex(join ":", $sid, $time, $user, $self->magic_string)
	; return join ":", $hash, $sid, $time, $user
	}


; sub load_token
	{ my ($self, $token) = @_
	; if ($self->session and $token = $self->session->param('CBA_Token') )
		{ require Digest::MD5
		; my ($digest,$sid,$time,$username) = split /:/, $token, 4
		; if ($digest eq Digest::MD5::md5_hex(join ":",, $sid, $time, $username, $self->magic_string) )
			{ $self->user( $self->User_factory->new(id => $username) || $self->User_factory->anonymous)
			}
		}
	}


; sub load_factory
	{ ref $_ 
		? 1 
		: eval { require File::Spec->catfile( split /::/ ) . ".pm"}
	}

=head1 NAME

CGI::Builder::Auth::Context - Encapsulate an authentication context for an application

=head1 DESCRIPTION

The Class provides an API for manipulating the User and Group tables. 

The context object keeps track of who the current user is and what groups that
user belongs to. The username 'anonymous' is used to indicate that a user is
not currently logged in. The name 'anonymous' is reserved and may not be used
in the real user database.

When the context object is created, it checks the current session (if
available) for an authentication token, and restores the context to its
previous state based on this token. That is, it automatically logs in the user.

=head1 CLASS METHODS

=head2 Manipulate the User table ("htpasswd")

=head3 C<user_list>

Returns a list of all users in the user table, as user objects.


=head3 C<add_user(\%attributes)>

Adds the user to the table. Returns the user object on success, false on
failure. Will fail if a user already exists with that name.

Required Attributes:

=over

=item * username

=item * password

=back

Additional, customizable attributes may be supported in a future release.


=head3 C<delete_user($user)>

Deletes the named user from the table. The $user parameter may be a user object
or a string containing the username. Returns true on success, false on failure.


=head2 Manipulate the Group table ("htgroup")

=head3 C<group_list>

Returns a list of all groups in the group table, as group objects.


=head3 C<add_group('groupname')>

Adds the group to the table. Returns the group object on success, false on
failure. Will fail if a group already exists with that name.


=head3 C<delete_group($group)>

Deletes the named group from the table. The $group parameter may be a group
object or a string containing the groupname. Returns true on success, false on
failure.


=head3 C<add_member($group,@users)>

Make the @users members of the named $group. The $group parameter may be a
group object or a string containing the groupname. The @users parameter may
contain either user objects, strings containing usernames, or any combination.
Returns true on success, false on failure.


=head3 C<remove_member($group,@users)>

Remove the @users from the named $group (without removing the user account
itself). The $group parameter may be a group object or a string containing the
groupname. The @users parameter may contain either user objects, strings
containing usernames, or any combination.  Returns true on success, false on
failure.


=head3 C<group_members($group)>

Returns a list of all users who are members of the group. The list will contain
user objects. The $group parameter may be a group object or a string containing
the groupname.


=head1 INSTANCE (OBJECT) METHODS

=head3 C<user([$new_user])>

Returns the current user for this context (your application). Optionally sets
the current user to the value passed in $new_user, but normally you will use
C<login> to set the user instead, because C<login> validates the password and
then updates the session. This method does neither. If provided, $new_user
I<must> be a user object, not a string.  

Defaults to the non-existent user 'anonymous'.


=head3 C<login('username','password')>

If the password matches the one in the user database for the named user, sets
the current user for this context, saves an authentication token to the current
session (if available), and returns the user object. Otherwise, returns false
and does not change the context nor the session.


=head3 C<logout>

Sets the current user to the anonymous user, and removes the authentication
token from the session (if available).


=head3 C<require_valid_user>

Returns true if the current user for this context is a real user in the
database (rather than the default anonymous user).


=head3 C<require_group(@groups)>

Returns true if the current user is a member of at least one of the @groups.
The @groups parameter may contain group objects, strings, or any combination.


=head3 C<require_user(@users)>

Returns true if the current user is one of the @users. The @users parameter may
contain either user objects, strings containing usernames, or any combination.

=cut
	
"Copyright 2004 Vincent Veselosky [[http://control-escape.com]]";
