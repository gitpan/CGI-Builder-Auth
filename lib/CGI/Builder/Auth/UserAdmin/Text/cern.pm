# $Id: cern.pm,v 1.1.1.1 1997/12/11 21:47:37 lstein Exp $

package CGI::Builder::Auth::UserAdmin::Text::cern;
@ISA = qw(CGI::Builder::Auth::UserAdmin::Text);
$VERSION = (qw$Revision: 1.1.1.1 $)[1];

#tweedle dee, tweedle dumb
sub new {
    my($class) = shift;
    CGI::Builder::Auth::UserAdmin::Text::new($class, DLM => ":", @_);
}


1;
