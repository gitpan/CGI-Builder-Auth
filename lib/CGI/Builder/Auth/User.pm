package CGI::Builder::Auth::User
; use strict
; use CGI::Builder::Auth::UserAdmin
; use Digest::MD5 'md5_hex'

; use Class::constr 
(	{ name => 'new', init => '_real' }
,	{ name => 'anonymous', init => '_anon' }
)
; use Class::groups
(	{ name => 'config'
	, default =>
		{ DBType  => 'Text' # type of database, one of 'DBM', 'Text', or 'SQL'
		, DB      => '.htpasswd' # database name
#		, Server  => 'apache'
#		, Encrypt => 'MD5'
		, Encrypt => 'crypt'
#		, Locking => 1
#		, Path    => '.'
		, Debug   => 0
		# read, write and create flags. There are four modes: rwc - the default,
		# open for reading, writing and creating. rw - open for reading and
		# writing. r - open for reading only. w - open for writing only.
#		, Flags   => 'rwc'

		# FOR DBI 
#		, Host    => 'localhost'
#		, Port    => ???
#		, User    => ''
#		, Auth    => ''
#		, Driver  => 'mysql'
#		, UserTable  => 'user'
#		, NameField  => 'user'
#		, PasswordField  => 'password'
		
		# FOR DBM Files
#		, DBMF => 'NDBM'
#		, Mode => 0644
		}
	}
)
; use Class::props
( 	{ name => '_user_admin'
	, default => sub { CGI::Builder::Auth::UserAdmin->new(%{$_[0]->config}) }
	}
, 	{ name => 'realm'
	, default => 'main'
	}
)
; use Object::props ('id')

; use overload
	(	'""' => 'as_string'
	,	fallback => 1
	)
# Overload Magic
; sub as_string { $_[0]->id }

# INIT Routines

# Cancel construction if requested user does not exist
; sub _real { $_[0] = undef unless $_[0]->exists }

# Force anonymous even if caller foolishly passed an ID
; sub _anon { $_[0]->id('anonymous') }


#---------------------------------------------------------------------
# Can be called as class method or object method.
#---------------------------------------------------------------------
; sub list { $_[0]->_user_admin->list }

# Calling add as object method should work, but does not make sense.
# Do not document it.
; sub add 
	{ my ($self, $data) = @_
	; my $username = delete $data->{'username'}
	; my $password = delete $data->{'password'}
    ; $password = join(":",$username,$self->realm,$password)
		if $self->_user_admin->{ENCRYPT} eq 'MD5'
	; return if __PACKAGE__->exists($username);
	; return $self->_user_admin->add($username, $password, $data)
		? $self->new(id => $username)
		: undef
	}
; sub exists 
	{ ref $_[0] 
		? $_[0]->_user_admin->exists($_[0]->id) 
		: $_[0]->_user_admin->exists($_[1]) 
	}
; sub delete 
	{ ref $_[0] 
		? $_[0]->_user_admin->delete($_[0]->id) 
		: $_[0]->_user_admin->delete($_[1]) 
	}
; sub suspend 
	{ ref $_[0] 
		? $_[0]->_user_admin->suspend($_[0]->id) 
		: $_[0]->_user_admin->suspend($_[1]) 
	}
; sub unsuspend 
	{ ref $_[0] 
		? $_[0]->_user_admin->unsuspend($_[0]->id) 
		: $_[0]->_user_admin->unsuspend($_[1]) 
	}

; sub password_matches
	{ my ($self, $passwd) = @_
    ; return unless $self->exists
    ; $passwd = join(":",$self->id,$self->realm,$passwd)
		if $self->_user_admin->{ENCRYPT} eq 'MD5'
		
	; my $stored_passwd = $self->_user_admin->password($self->id)
	; return $self->_user_admin->{ENCRYPT} eq 'crypt'
		? crypt($passwd,$stored_passwd) eq $stored_passwd
		: $self->_user_admin->encrypt($passwd) eq $stored_passwd
    }




"Copyright 2004 Vincent Veselosky [[http://control-escape.com]]";
