# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 19;

BEGIN { 
	# Clean up from previous tests
	unlink('.htgroup');
	use_ok('CGI::Builder::Auth::Group');
};
use CGI::Builder::Auth::User;
my ($user, $group, @users, %users, @groups, %groups);

#-------------------------------------------------------------------- 
# Class Methods
#-------------------------------------------------------------------- 
isa_ok(CGI::Builder::Auth::Group->_group_admin, 'CGI::Builder::Auth::GroupAdmin', '_group_admin');

@groups = CGI::Builder::Auth::Group->list;
ok(!@groups,	'group_list initially empty');
# ok(!CGI::Builder::Auth::Group->exists('testgroup'), 	"exists class method");

$group = CGI::Builder::Auth::Group->load(id => 'testgroup');
is($group, undef,  	'$group not constructed when does not exist');

#-------------------------------------------------------------------- 
# Add group
#-------------------------------------------------------------------- 
$group = CGI::Builder::Auth::Group->add('testgroup');
isa_ok($group, 'CGI::Builder::Auth::Group', 	'$group');
ok(CGI::Builder::Auth::Group->load(id => 'testgroup'), "load after create");

#-------------------------------------------------------------------- 
# Object Methods
#-------------------------------------------------------------------- 

# ok($group->exists, "exists as object method");
is($group->id, 'testgroup', "id");


#-------------------------------------------------------------------- 
# List with multiple groups
#-------------------------------------------------------------------- 
$group = CGI::Builder::Auth::Group->add('mygroup');

@groups = CGI::Builder::Auth::Group->list;
%groups = map { $_ => 1 } @groups;
ok(@groups, 	"list as class method");
ok($groups{'testgroup'} && $groups{'mygroup'},	"group_list complete.");


#-------------------------------------------------------------------- 
# Membership
#-------------------------------------------------------------------- 
CGI::Builder::Auth::User->add({ username => 'bob', password => '1'});
CGI::Builder::Auth::User->add({ username => 'carol', password => '1'});

ok($group->add_member('bob'), 	'add_member as object method');
ok(CGI::Builder::Auth::Group->add_member('mygroup','carol'), 	'add_member as class method');

@users = $group->member_list;
%users = map { $_ => 1 } @users;
ok($users{'bob'} && $users{'carol'},	"member_list complete.");

ok($group->remove_member('bob'), 	'remove_member as object method');
ok(CGI::Builder::Auth::Group->remove_member('mygroup','carol'), 	'remove_member as class method');

@users = $group->member_list;
ok(!$group->member_list,	"removed members successfully");

#-------------------------------------------------------------------- 
# Add group that exists
#-------------------------------------------------------------------- 
$group = CGI::Builder::Auth::Group->add('testgroup');
ok(!$group, 	"add fails when group exists");

#-------------------------------------------------------------------- 
# Delete
#-------------------------------------------------------------------- 
$group = CGI::Builder::Auth::Group->load(id => 'testgroup');
ok($group->delete,	"delete as object method");
ok(CGI::Builder::Auth::Group->load(id => 'mygroup')->delete, 	"delete 'in place'");
ok(!CGI::Builder::Auth::Group->list,	"groups deleted successfully");


# vim:ft=perl:tw=80:
