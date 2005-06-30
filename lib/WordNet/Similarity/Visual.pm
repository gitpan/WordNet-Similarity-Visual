package WordNet::Similarity::Visual;

use 5.008004;
use WordNet::Similarity::Visual::QueryDataInterface;
use WordNet::Similarity::Visual::GUI_Window;
use WordNet::Similarity::Visual::SimilarityInterface;
use Gtk2 '-init';
use strict;
use warnings;
use constant TRUE  => 1;
use constant FALSE => 0;
my $main_window;
my $querydata_vbox;
my $similarity_vbox;
our $main_statusbar;
our $VERSION = '0.02';


sub new
{
  my ($class) = @_;
  my $self = {};
  bless $self, $class;
}


sub initialize
{
  my ($self)=@_;
  $self->configure;
  $self->{ main_window } = WordNet::Similarity::Visual::GUI_Window->new;
  $self->{ main_window }->initialize("WordNet::Similarity GUI",0, 645,500);
    $self->{ main_statusbar } = Gtk2::Statusbar->new;
    my $main_menu = Gtk2::MenuBar->new();
  $self->{ main_window }->pack_start($main_menu,FALSE, FALSE, 0);
    my $tabbedwindow = Gtk2::Notebook->new;
    $tabbedwindow->set_show_border(0);
      my $querydata_scrollwindow = Gtk2::ScrolledWindow->new;
      my $similarity_scrollwindow = Gtk2::ScrolledWindow->new;
      $self->{ querydata_vbox } = WordNet::Similarity::Visual::QueryDataInterface->new;
      $self->{ similarity_vbox } = WordNet::Similarity::Visual::SimilarityInterface->new;
      $self->{ querydata_vbox }->initialize($self);
      $self->{ similarity_vbox }->initialize($self);
      $similarity_scrollwindow->add_with_viewport($self->{ similarity_vbox }->{ vbox });
      $similarity_scrollwindow->set_policy("GTK_POLICY_NEVER", "GTK_POLICY_AUTOMATIC");
      $querydata_scrollwindow->add_with_viewport($self->{ querydata_vbox }->{ vbox });
      $querydata_scrollwindow->set_policy("GTK_POLICY_NEVER", "GTK_POLICY_AUTOMATIC");
    $tabbedwindow->append_page($querydata_scrollwindow, "WordNet::QueryData");
    $tabbedwindow->append_page($similarity_scrollwindow, "WordNet::Similarity");
  $self->{ main_window }->pack_start($tabbedwindow,TRUE, TRUE,0);
  $self->{ main_window }->pack_end($self->{ main_statusbar },FALSE, FALSE, 0);
  $self->{ main_window }->display;
}

# This function writes the initial configuration files for the various measures.
sub configure
{
  if (!chdir($ENV{ HOME } . "/.wordnet-similarity"))
  {
    mkdir ($ENV{ HOME } . "/.wordnet-similarity");
    open CONFIG, "+>".$ENV{ HOME } . "/.wordnet-similarity/config-path.conf";
    print CONFIG "WordNet::Similarity::path\ntrace::1\ncache::1\nmaxCacheSize::5000\nrootNode::1";
    close CONFIG;
    open CONFIG, "+>".$ENV{ HOME } . "/.wordnet-similarity/config-wup.conf";
    print CONFIG "WordNet::Similarity::wup\ntrace::1\ncache::1\nmaxCacheSize::5000\nrootNode::1";
    close CONFIG;
    open CONFIG, "+>".$ENV{ HOME } . "/.wordnet-similarity/config-hso.conf";
    print CONFIG "WordNet::Similarity::hso\ntrace::1\ncache::1\nmaxCacheSize::5000";
    close CONFIG;
    open CONFIG, "+>".$ENV{ HOME } . "/.wordnet-similarity/config-lch.conf";
    print CONFIG "WordNet::Similarity::lch\ntrace::1\ncache::1\nmaxCacheSize::5000\nrootNode::1";
    close CONFIG;
  }
}

sub update_ui
{
  my ($self) = @_;
  $self->{ main_window }->update_ui();
}

sub set_statusmessage
{
  my ($self, $context, $message) = @_;
  my $status_context_id = $self->{ main_statusbar }->get_context_id("MainStatusBar");
  $self->{ main_statusbar }->push($status_context_id,$message);
  $self->{ main_window }->update_ui();
}
1;
__END__

=head1 NAME

WordNet::Similarity::Visual - Perl extension for providing visualizatio tools for WordNet::Similarity

=head1 SYNOPSIS

  use WordNet::Similarity::Visual;

  This module provides a graphical user interface for WordNet::Similarity and visualization tools for the path based measures built in
  WordNet::Similarity. These visualization tools will make it easier for the user to understand the concepts behind these semantic measures.

=head1 DESCRIPTION

  This module provides a graphical user interface for WordNet::Similarity and visualization tools for the path based measures built in
  WordNet::Similarity. These visualization tools will make it easier for the user to understand the concepts behind these semantic measures.

=head2 Methods

The following methods are defined in this package:

=head3 Public methods

=over

=item $obj->new

The constructor for WordNet::Similarity::Visual objects.

Return value: the new blessed object

=item $obj->initialize

To initialize the Graphical User Interface and pass the control to it.


=head1 SEE ALSO

WordNet::Similarity
WordNet::QueryData

Mailing List: E<lt>wn-similarity@yahoogroups.comE<gt>

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