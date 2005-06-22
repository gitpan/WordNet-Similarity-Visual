package WordNet::Similarity::Visual::GUI_Window;

use 5.008004;
use strict;
use warnings;
our $VERSION = '0.01';
use Gtk2 '-init';
use constant TRUE  => 1;
use constant FALSE => 0;
my $window;
my $vbox;

sub new
{
  my ($class) = @_;
  my $self = {};
  bless $self, $class;
}

sub initialize
{
  my ($self, $title, $b_width, $width, $height) = @_;
  
  $self->{ window } = Gtk2::Window->new("toplevel");
  $self->{ window }->set_title($title);
  #Create an instance of window
  $self->{ window }->set_border_width($b_width);
  # set the window border width
  $self->{ window }->set_default_size($width,$height);
  $self->{ window }->signal_connect(destroy => sub { Gtk2->main_quit; });
  #$self->{ window }->
  # connect the quit signal with the window
  # quit from the GTK blocking call when the exit signal is recieved
  $self->{ vbox } = Gtk2::VBox->new(FALSE,0);
  $self->{ window }->add($self->{ vbox });
#   $self->{ window }->signal_connect(focus=>sub { my ($self)=@_;
#                                                       $self->show_all();
#                                                        });
}

sub update_ui
{
  Gtk2->main_iteration while (Gtk2->events_pending);
}

sub add
{
  my ($self, $toadd) = @_;
  $self->{ vbox }->add($toadd);
}

sub pack_start
{
  my ($self, @args) = @_;
  $self->{ vbox }->pack_start(@args);
}

sub pack_end
{
  my ($self, @args) = @_;
  $self->{ vbox }->pack_start(@args);
}

sub message
{
  my ($self, $flag, $msgtype, $buttons, $msg) = @_;
  my $message = Gtk2::MessageDialog->new( $self->{ window }, $flag, $msgtype, $buttons, $msg);
  my $response = $message->run();
  if ($response =~ "ok" )
  {
    $message->destroy();
  }
}
sub show_all
{
  my ($self)=@_;
  $self->{ window }->show_all;
}
sub display
{
  my ($self) = @_;
  $self->{ window }->show_all;
  Gtk2->main;
}


1;
__END__

=head1 NAME

Provides the basic GUI for WordNet::Similarity

=head1 SYNOPSIS

  use WordNet::Similarity::Visual;
  
  This module provides a graphical user interface for WordNet::Similarity and visualization tools for the path based measures built in
  WordNet::Similarity. These visualization tools will make it easier for the user to understand the concepts behind these semantic measures.

=head1 DESCRIPTION
  
  This module provides a graphical user interface for WordNet::Similarity and visualization tools for the path based measures built in
  WordNet::Similarity. These visualization tools will make it easier for the user to understand the concepts behind these semantic measures.


=head1 SEE ALSO

Gtk2
Gnome2

=head1 AUTHOR

Saiyam Kohli, E<lt>kohli003@d.umn.eduE<gt>

Ted Pedersen, University of Minnesota, Duluth
tpederse@d.umn.edu

Copyright (c) 2005-2006

Saiyam Kohli, University of Minnesota, Duluth
kohli003@d.umn.edu

Ted Pedersen, University of Minnesota, Duluth
tpederse@d.umn.edu

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to

The Free Software Foundation, Inc.,
59 Temple Place - Suite 330,
Boston, MA  02111-1307, USA.

=cut
