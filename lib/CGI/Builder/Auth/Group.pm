package CGI::Builder::Auth::Group
; use strict
; use CGI::Builder::Auth::GroupAdmin
; use CGI::Builder::Auth::User
; use Class::constr { init => 'init' }

; use Class::groups
(	{ name => 'config'
	, default =>
		{ DBType  => 'Text' # type of database, one of 'DBM', 'Text', or 'SQL'
		, DB      => '.htgroup' # database name
#		, Server  => 'apache'
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
		, Driver  => 'mysql'
		, GroupTable  => 'group'
#		, NameField  => 'user'
#		, GroupField  => 'group'
		
		# FOR DBM Files
#		, DBMF => 'NDBM'
#		, Mode => 0644
		}
	}
)
; use Class::props
( 	{ name => '_group_admin'
	, default => sub { CGI::Builder::Auth::GroupAdmin->new(%{$_[0]->config}) }
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

; sub as_string { $_[0]->id }

# Cancel construction if requested group does not exist
; sub init { $_[0] = undef unless $_[0]->exists }


#---------------------------------------------------------------------
# Can be called as class method or object method.
#---------------------------------------------------------------------
; sub list { $_[0]->_group_admin->list }

# Calling add as object method should work, but does not make sense.
# Do not document it.
; sub add 
	{ my ($self, $data) = @_
	; my $group = ref $data ? $data->{group} : $data;
	; return if __PACKAGE__->exists($group);
	; $self->_group_admin->create($group) or warn "Creation Failed"
	; return $self->new(id => $group)
	}
; sub exists 
	{ ref $_[0] 
		? $_[0]->_group_admin->exists($_[0]->id) 
		: $_[0]->_group_admin->exists($_[1]) 
	}
; sub delete 
	{ ref $_[0] 
		? $_[0]->_group_admin->remove($_[0]->id) 
		: $_[0]->_group_admin->remove($_[1]) 
	}

# 
# FIXME add_member & remove_member appear to succeed when !exists user
# 
; sub add_member 
	{ my ($self, @users) = @_
	; my $group = ref $self ? $self->id : shift @users;
	; return if !__PACKAGE__->exists($group)
	; for my $user (@users)
		{ next unless CGI::Builder::Auth::User->exists($user)
		; $self->_group_admin->add($user, $group)
		}
	; 1
	}
; sub remove_member 
	{ my ($self, @users) = @_
	; my $group = ref $self ? $self->id : shift @users
	; return if !__PACKAGE__->exists($group)
	; for my $user (@users)
		{ $self->_group_admin->delete($user, $group)
		}
	; 1
	}
; sub member_list
	{ my ($self, $group) = @_
	; $group = $group || $self->id
	; return if !__PACKAGE__->exists($group)
	; $self->_group_admin->list($group)
	}


"Copyright 2004 Vincent Veselosky [[http://control-escape.com]]";
