# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 20;

BEGIN { 
	# Clean up from previous tests
	unlink('.htpasswd');
	use_ok('CGI::Builder::Auth::User');
};

my ($user, $user2, @users, %users, @groups, %groups);

#-------------------------------------------------------------------- 
# Class Methods
#-------------------------------------------------------------------- 
isa_ok(CGI::Builder::Auth::User->_user_admin, 'CGI::Builder::Auth::UserAdmin', '_user_admin');

@users = CGI::Builder::Auth::User->list;
ok(!@users,	'user_list initially empty');
# ok(!CGI::Builder::Auth::User->exists('bob'), 	"exists class method");

$user = CGI::Builder::Auth::User->load(id => 'bob');
is($user, undef,  	'$user not constructed when does not exist');

$user = CGI::Builder::Auth::User->anonymous;
is($user, 'anonymous',  'can create anonymous user');

#-------------------------------------------------------------------- 
# Add user
#-------------------------------------------------------------------- 
$user = CGI::Builder::Auth::User->add({username => 'bob', password => 'password'});
isa_ok($user, 'CGI::Builder::Auth::User', 	'$user');
ok(CGI::Builder::Auth::User->load(id => 'bob'), "load after create");

#-------------------------------------------------------------------- 
# Object Methods
#-------------------------------------------------------------------- 

# ok($user->exists, "exists as object method");
is($user->id, 'bob', "id");


#-------------------------------------------------------------------- 
# List with multiple users
#-------------------------------------------------------------------- 
$user = CGI::Builder::Auth::User->add({username => 'carol', password => 'password'});

@users = CGI::Builder::Auth::User->list;
%users = map { $_ => 1 } @users;
ok(@users, 	"list as class method");
ok($users{'bob'} && $users{'carol'},	"user_list complete.");


#-------------------------------------------------------------------- 
# Passwords and Suspend
#-------------------------------------------------------------------- 
ok($user->password_matches('password'), 	'password matches');
ok($user->suspend, 	'suspend');
ok(!$user->password_matches('password'), 	'password does not match when suspended');
ok($user->unsuspend, 	'unsuspend');
ok($user->password_matches('password'), 	'password matches after unsuspend');

#-------------------------------------------------------------------- 
# Add user should fail in these cases
#-------------------------------------------------------------------- 
$user = CGI::Builder::Auth::User->add({username => 'bob', password => 'password'});
ok(!$user, 	"add fails when user exists");

$user = CGI::Builder::Auth::User->add({username => 'anonymous', password => 'password'});
ok(!$user, 	"cannot 'create' anonymous user");

#-------------------------------------------------------------------- 
# Delete
#-------------------------------------------------------------------- 
$user = CGI::Builder::Auth::User->load(id => 'bob');
ok($user->delete,	"delete as object method");
ok(CGI::Builder::Auth::User->load(id => 'carol')->delete, 	"delete 'in place'");
ok(!CGI::Builder::Auth::User->list,	"users deleted successfully");


# vim:ft=perl:tw=80:
