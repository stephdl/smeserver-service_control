#!/usr/bin/perl -w
#----------------------------------------------------------------------
# $Id: servicetotal.pm,v 1.31 2003/04/08 15:28:55 mvanhees Exp $
# vim: ft=perl ts=4 sw=4 et:
#----------------------------------------------------------------------
# copyright (C) 2004 Pascal Schirrmann
# copyright (C) 2002 Mitel Networks Corporation
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
#----------------------------------------------------------------------

package esmith::FormMagick::Panel::servicecontrol;

use strict;
use esmith::FormMagick;
use esmith::cgi;
use esmith::util;
use esmith::config;
use esmith::db;
use esmith::event;
use esmith::ConfigDB;

use File::Basename;
use Carp;
use Exporter;

use constant TRUE => 1;
use constant FALSE => 0;

our @ISA = qw(esmith::FormMagick Exporter);

our @EXPORT = qw(
     main
     displayService
    );

our $VERSION = sprintf '%d.%03d', q$Revision: 1.1 $ =~ /: (\d+).(\d+)/;

my $config = esmith::ConfigDB->open;

=head1 NAME

esmith::FormMagick::Panels::serviceactivated - useful panel functions

=head1 SYNOPSIS

    use esmith::FormMagick::Panels::servicecontrol

    my $panel = esmith::FormMagick::Panel::servicecontrol->new();
    $panel->display();

=head1 DESCRIPTION

This module is the backend to the servicecontrol panel, responsible for
supplying all functions used by that panel. It is a subclass of
esmith::FormMagick itself, so it inherits the functionality of a FormMagick
object.

=head2 new

This is the class constructor.

=cut

sub new {
    shift;
    my $self = esmith::FormMagick->new();
    $self->{calling_package} = (caller)[0];
    bless $self;
    return $self;
}

=head2 main

Main methode select correct action

=cut

sub main {
    my ($fm) = @_;
    my $action = $fm->{cgi}->param('action') || '';
    my $wherenext = $fm->{cgi}->param('wherenext');

    $fm->debug_msg("Action: $action");
	$fm->debug_msg("Wherenext: $wherenext");

	# Everythings regarding service status
	#
    if ( $action eq 'ServiceChange' )
    {
      my $can= $fm->{cgi}->param('cancel') || 'no';
      my $service = $fm->{cgi}->param('service');
      if ( $can eq 'no' ) 
      {
          $fm->ServiceChange($service);
      } else {
        $fm->error("ACTION_CANCEL_USER");
      }
	# Everythings regarding TCP property
	#
    } elsif ( $action eq 'TCPPORTChange' )
    {
      my $can= $fm->{cgi}->param('cancel') || 'no';
      my $service = $fm->{cgi}->param('service');
      my $port = $fm->{cgi}->param('port');
      if ( $can eq 'no' )       
      {
          $fm->ServiceTCPChange($service,$port);
      } else
      {
          $fm->error("ACTION_CANCEL_USER");
      }
	# Everythings regarding ACCESS property
	#
    } elsif ( $action eq 'ACCESSChange' )
    {
      my $can= $fm->{cgi}->param('cancel') || 'no';
      my $service = $fm->{cgi}->param('service');
      if ( $can eq 'no' ) 
      {
          $fm->AccessChange($service);
      } else {
        $fm->error("ACTION_CANCEL_USER");
      }
    }
	
    $fm->wherenext($wherenext);
}

=head2 ServiceTCPChange

Change TCP Port of a service

=cut

sub ServiceTCPChange {
    my ($self, $service, $port) = @_;
    my $action;
    my $startScript;

    my $record = $config->get($service);

    $self->debug_msg("Service: $service");
	$self->debug_msg("Port: $port");
    $self->debug_msg("Old port: " . $record->prop("TCPPort"));

    if ($service =~ /^([-\@\w.]+)$/) {
        $service = $1;                  # $data now untainted 
    } else {
        die "Bad data in '$service'";  # log this somewhere 
    }
	
    if ( $record->prop("TCPPort") ne $port )
    {
        $record->set_prop("TCPPort", $port);
		$action="restart";
#expand all templates
    esmith::event::event_signal("service-expand");

# A hack since a lot db set as service don't have a service name in rc7.d
# THINK to change as same in sub ServiceChange and sub AccessChange
        $service = 'dovecot' if ( $service =~ 'imap');
        $service = 'httpd-e-smith' if ( $service eq 'modSSL');
        $service = 'httpd-e-smith' if ( $service eq 'php');
        $service = 'httpd-e-smith' if ( $service eq 'imp');
        $service = 'smb' if ( $service eq 'nmbd');
        $service = 'smb' if ( $service eq 'smbd');
        $service = 'clamd' if ( $service eq 'clamav');
        $service = 'dnscache' if ( $service eq 'dnscache.forwarder');
        $service = 'httpd-e-smith' if ( $service eq 'horde');
        $service = 'httpd-e-smith' if ( $service eq 'modPerl');
        $service = 'qpsmtpd' if ( $service eq 'smtpd');
        $service = 'sqpsmtpd' if ( $service eq 'ssmtpd');


   $startScript = glob("/etc/rc.d/rc7.d/S*$service");
    if ($startScript){     
    esmith::event::event_signal("service-one", $service, $action);}
		$self->success("SUCCESSFULLY_TCPPORT_CHANGE");
    } else {
        $self->success("SUCCESSFULLY_TCPPORT_NOCHANGE");
    }
    
}

=head2 ServiceChange

swap service status : stop or start the service

=cut

sub ServiceChange {
    my ($self, $service) = @_;
    my $action;
    my $startScript;

    my $record = $config->get($service);
    $self->debug_msg("Service: $service");
    $self->debug_msg("Actual status: " . $record->prop("status"));

    if ($service =~ /^([-\@\w.]+)$/) {
        $service = $1;                  # $data now untainted
    } else {
        die "Bad data in '$service'";  # log this somewhere
    }

    if ( $record->prop("status") eq 'enabled' )
    {
        $record->set_prop("status", "disabled");
		$action="stop";
    } else {
        $record->set_prop("status", "enabled");
		$action="start";
    }
#expand all templates
    esmith::event::event_signal("service-expand");

# A hack since a lot db set as service don't have a service name in rc7.d
# THINK to change as same in sub ServiceTCPChange and sub AccessChange

        $service = 'dovecot' if ( $service =~ 'imap');
        $service = 'httpd-e-smith' if ( $service eq 'modSSL');
        $service = 'httpd-e-smith' if ( $service eq 'php');
        $service = 'httpd-e-smith' if ( $service eq 'imp');
        $service = 'smb' if ( $service eq 'nmbd');
        $service = 'smb' if ( $service eq 'smbd');
        $service = 'clamd' if ( $service eq 'clamav');
        $service = 'dnscache' if ( $service eq 'dnscache.forwarder');
        $service = 'httpd-e-smith' if ( $service eq 'horde');
        $service = 'httpd-e-smith' if ( $service eq 'modPerl');
        $service = 'qpsmtpd' if ( $service eq 'smtpd');
        $service = 'sqpsmtpd' if ( $service eq 'ssmtpd');
            
    $startScript = glob("/etc/rc.d/rc7.d/S*$service");
    if ($startScript){     
    esmith::event::event_signal("service-one", $service, $action);}

    $self->success("SUCCESSFULLY_ACTIVATE_SERVICE");
}

=head2 displayNavig 

This will show the first level naviguation

=cut

sub displayNavig {
    my $self = shift;
    my $q = $self->{cgi};

    print '<table>';
	print '  <tr>';
	
	print '    <td>';
	print '      <form>';
	print '        <input type="hidden" name="page" value="0" />';
	print '        <input type="hidden" name="page_stack" value="" />';
	print '        <input type="hidden" name="action" value="SA" />';
	print '        <input type="hidden" name="wherenext" value="ServiceActivate" />';
	print '        <input type="submit" name="submit" value="' . $self->localise('SERVICE_FORM_ACTIVATE') . '" />';
	print '      </form>';
	print '    </td>';

	print '    <td>';
	print '      <form>';
	print '        <input type="hidden" name="page" value="0" />';
	print '        <input type="hidden" name="page_stack" value="" />';
	print '        <input type="hidden" name="action" value="SA" />';
	print '        <input type="hidden" name="wherenext" value="TCPPORTEdit" />';
	print '        <input type="submit" name="submit" value="' . $self->localise('SERVICE_FORM_TCPPORT') . '" />';
	print '      </form>';
	print '    </td>';

        print '    <td>';
        print '      <form>';
        print '        <input type="hidden" name="page" value="0" />';
        print '        <input type="hidden" name="page_stack" value="" />';
        print '        <input type="hidden" name="action" value="SA" />';
        print '        <input type="hidden" name="wherenext" value="ServiceAccess" />';
        print '        <input type="submit" name="submit" value="' . $self->localise('SERVICE_FORM_ACCESS') . '" />';
        print '      </form>';
        print '    </td>';

    print '  </tr>';
	print '</table>';

    return '';    
}

=head2 displayService

This return all service definies in serve

=cut

sub displayService {
    my $self = shift;
    my $q = $self->{cgi};
    my $prop_value;

    my @services = $config->services();    

    print '<table border="1">';
    print '  <tr>';
	print '    <td><b>' . $self->localise('SERVICE_NAME') . '</b></td>';
	print '    <td><b>' . $self->localise('SERVICE_STATUS') . '</b></td>';
	print '    <td><b>' . $self->localise('SERVICE_ACTION') . '</b></td>';
	print '  </tr>';
	
    foreach my $filter ( @services )
    {
        $prop_value = $config->get($filter)->prop("status") || "Error";
        if ($prop_value ne 'Error') {
            print '  <tr>';
            print '    <td>' . $filter . '</td>';
			print '    <td>' . $prop_value . '</td>';
			print '    <td>';
            print '      <form>';
            print '        <input type="hidden" name="page" value="0" />';
            print '        <input type="hidden" name="page_stack" value="" />';
            print '        <input type="hidden" name="action" value="ServiceConfirm" />';
            print '        <input type="hidden" name="service" value="' . $filter . '" />';
            print '        <input type="hidden" name="wherenext" value="ServiceConfirm" />';
            print '        <input type="submit" name="submit" value="' . $self->localise('SERVICE_STATUS_' . $prop_value) . '" />';
            print '      </form>';
            print '    </td>';
			print '  </tr>';
        }
    }
    print '</table>';
    return '';
}

=head2 displayConfirnActivate

Display confirmation message for service activation part

=cut

sub displayConfirmActivate {
    my ($self) = @_;
    my $service = $self->{cgi}->param('service') || '';
    
    my $q = $self->{cgi};
    
    my $record = $config->get($service);

    print '<form>';
    print '  <input type="hidden" name="page" value="0" />';
    print '  <input type="hidden" name="page_stack" value="" />';
    print '  <input type="hidden" name="action" value="ServiceChange" />';
    print '  <input type="hidden" name="service" value="' . $service . '" />';
    print '  <input type="hidden" name="wherenext" value="ServiceActivate" />';
    print '  <p><b>' . $service . '</b></p>';
    print '  <p>' . $self->localise('ALERT' . $record->prop("status")) . '</p>';    
    print '  <input type="submit" name="cancel" value="' . $self->localise('CANCEL') . '" />';
    print '  <input type="submit" name="submit" value="' . $self->localise('VALIDE') . '" />';
    print '</form>';

    return '';
}

=head2 displayConfirmTCP

Display confirmation message for TCP edit part

=cut
    
sub displayConfirmTCP {
    my ($self) = @_;
    my $service = $self->{cgi}->param('service') || '';
    my $port = $self->{cgi}->param('port') || '';

    my $q = $self->{cgi};
    
    print '<form>';
    print '  <input type="hidden" name="page" value="0" />';
    print '  <input type="hidden" name="page_stack" value="" />';
    print '  <input type="hidden" name="action" value="TCPPORTChange" />';
    print '  <input type="hidden" name="service" value="' . $service . '" />';
    print '  <input type="hidden" name="port" value="' . $port . '" />';
    print '  <input type="hidden" name="wherenext" value="TCPPORTEdit" />';
    print '  <p><b>' . $service . '</b></p>';
    print '  <p>' . $self->localise('ALERTTCP') . '</p>';
    print '  <input type="submit" name="cancel" value="' . $self->localise('CANCEL') . '" />';
    print '  <input type="submit" name="submit" value="' . $self->localise('VALIDE') . '" />';
    print '</form>';
            
    return '';
}
            
=head2 displayServiceTcp

This return all service definies in serve

=cut
    
sub displayServiceTcp {
    my $self = shift;
    my $q = $self->{cgi};
    my $prop_value;
    
    my @services = $config->services();
    
    print '<table border="1">';
    print '  <tr>';
	print '    <td><b>' . $self->localise('SERVICE_NAME') . '</b></td>';
	print '    <td><b>' . $self->localise('SERVICE_TCPPORT') . '</b></td>';
	print '    <td><b>' . $self->localise('SERVICE_ACTION') . '</b></td>';
	print '  </tr>';
	
    foreach my $filter ( @services )
    {
        $prop_value = $config->get($filter)->prop("TCPPort") || "Error";
        if ($prop_value ne 'Error') {
            print '  <tr>';
            print '    <td>' . $filter . '</td>';
            print '    <td>';
			print '      <form>';
            print '        <input type="hidden" name="page" value="0" />';
            print '        <input type="hidden" name="page_stack" value="" />';
            print '        <input type="hidden" name="action" value="TCPConfirm" />';
            print '        <input type="hidden" name="service" value="' . $filter . '" />';
            print '        <input type="hidden" name="wherenext" value="TCPConfirm" />';
            print '        <input type="text" name="port" value="' . $prop_value . '" />';
			print '    </td>';
			print '    <td>';
            print '        <input type="submit" name="submit" value="' . $self->localise('VALIDE') . '" />';
            print '      </form>';
            print '    </td>';
			print '  </tr>';
        }
    }
    print '</table>'; 
    return '';
}

=head2 displayServiceAccess

This return all service definies in server

=cut
    
sub displayServiceAccess {
    my $self = shift;
    my $q = $self->{cgi};
    my $prop_value;

    my @services = $config->services();    

    print '<table border="1">';
    print '  <tr>';
	print '    <td><b>' . $self->localise('SERVICE_NAME') . '</b></td>';
	print '    <td><b>' . $self->localise('SERVICE_ACCESS') . '</b></td>';
	print '    <td><b>' . $self->localise('SERVICE_ACCESS_ACTION') . '</b></td>';
	print '  </tr>';
	
    foreach my $filter ( @services )
    {
        $prop_value = $config->get($filter)->prop("access") || "Error";
        if ($prop_value ne 'Error') {
            if ($prop_value eq 'private' || $prop_value eq 'public') {
                print '  <tr>';
                print '    <td>' . $filter . '</td>';
	        print '    <td>' . $prop_value . '</td>';
	        print '    <td>';
                print '      <form>';
                print '        <input type="hidden" name="page" value="0" />';
                print '        <input type="hidden" name="page_stack" value="" />';
                print '        <input type="hidden" name="action" value="ServiceAccessConfirm" />';
                print '        <input type="hidden" name="service" value="' . $filter . '" />';
                print '        <input type="hidden" name="wherenext" value="ServiceAccessConfirm" />';
                print '        <input type="submit" name="submit" value="' . $self->localise('SERVICE_ACCESS_' . $prop_value) . '" />';
                print '      </form>';
                print '    </td>';
	        print '  </tr>';
            }
        }
    }
    print '</table>';
    return '';
}

=head2 displayConfirmAccess

Display confirmation message for service activation part

=cut

sub displayConfirmAccess {
    my ($self) = @_;
    my $service = $self->{cgi}->param('service') || '';
    
    my $q = $self->{cgi};
    
    my $record = $config->get($service);

    print '<form>';
    print '  <input type="hidden" name="page" value="0" />';
    print '  <input type="hidden" name="page_stack" value="" />';
    print '  <input type="hidden" name="action" value="ACCESSChange" />';
    print '  <input type="hidden" name="service" value="' . $service . '" />';
    print '  <input type="hidden" name="wherenext" value="ServiceAccess" />';
    print '  <p><b>' . $service . '</b></p>';
    print '  <p>' . $self->localise('ALERT' . $record->prop("access")) . '</p>';    
    print '  <input type="submit" name="cancel" value="' . $self->localise('CANCEL') . '" />';
    print '  <input type="submit" name="submit" value="' . $self->localise('VALIDE') . '" />';
    print '</form>';

    return '';
}

=head2 AccessChange

swap service access

=cut

sub AccessChange {
    my ($self, $service) = @_;
    my $action;
    
    my $record = $config->get($service);
    $self->debug_msg("Service: $service");
    $self->debug_msg("Actual status: " . $record->prop("access"));

    if ($service =~ /^([-\@\w.]+)$/) {
        $service = $1;                  # $data now untainted
    } else {
        die "Bad data in '$service'";  # log this somewhere
    }
    $action="restart";
    if ( $record->prop("access") eq 'private' )
    {
        $record->set_prop("access", "public");
    } else {
        $record->set_prop("access", "private");
    }
#expand all templates
    esmith::event::event_signal("service-expand");

# A hack since a lot db set as service don't have a service name in rc7.d
# THINK to change as same in sub ServiceChange and sub ServiceTCPChange
        $service = 'dovecot' if ( $service =~ 'imap');
        $service = 'httpd-e-smith' if ( $service eq 'modSSL');
        $service = 'httpd-e-smith' if ( $service eq 'php');
        $service = 'httpd-e-smith' if ( $service eq 'imp');
        $service = 'smb' if ( $service eq 'nmbd');
        $service = 'smb' if ( $service eq 'smbd');
        $service = 'clamd' if ( $service eq 'clamav');
        $service = 'dnscache' if ( $service eq 'dnscache.forwarder');
        $service = 'httpd-e-smith' if ( $service eq 'horde');
        $service = 'httpd-e-smith' if ( $service eq 'modPerl');
        $service = 'qpsmtpd' if ( $service eq 'smtpd');
        $service = 'sqpsmtpd' if ( $service eq 'ssmtpd');


   $startScript = glob("/etc/rc.d/rc7.d/S*$service");
    if ($startScript){
    esmith::event::event_signal("service-access");}

    $self->success("SUCCESSFULLY_ACTIVATE_SERVICE");
}

;
