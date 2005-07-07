package WordNet::Similarity::Visual;

=head1 NAME

WordNet::Similarity::Visual - Perl extension for providing visualization tools
for WordNet::Similarity

=head1 SYNOPSIS

=head2 Basic Usage Example

  use WordNet::Similarity::Visual;

  $gui = WordNet::Similarity::Visual->new;

  $gui->initialize;

=head1 DESCRIPTION

This package provides a graphical extension for WordNet::Similarity.
It provides a gui for WordNet::Similarity and visualization tools for
the various edge counting measures like path, wup, lch and hso.

=head2 Methods

The following methods are defined in this package:

=head3 Public methods

=over

=cut

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
our $VERSION = '0.04';

=item  $obj->new

The constructor for WordNet::Similarity::Visual objects.

Return value: the new blessed object

=cut


sub new
{
  my ($class) = @_;
  my $self = {};
  bless $self, $class;
}

=item  $obj->initialize

To initialize the Graphical User Interface and pass the control to it.

=cut

sub initialize
{
  my ($self)=@_;
  $self->configure;
  $self->{ main_window } = WordNet::Similarity::Visual::GUI_Window->new;
  $self->{ main_window }->initialize("WordNet::Similarity GUI",0, 800,600);
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



=back

=head2 Discussion

The path measure defines the semantic similarity between two concepts as the
inverse of length of the shortest path between the concepts in the hypernym
trees of WordNet. This module displays the hypernym trees for both the concepts
and the shortest path between these concepts.

The wup measure is based on the method proposed by Wu & Palmer and uses the
depth of the two concepts in the hypernym tree and the depth of the Least Common
Subscumer. It is based on the  This module enables the user to view the
hypertrees for the concepts.  The lch measure implements a semantic measure
proposed by Leacock & Chodrow. It uses the length of the shortest path between
the two concepts and scales it by the maximum depth of the tree to compute the
similarity score. For this measure this module displays the shortest path.

The hso measure measure computes the semantic relatedness between two concepts
using the method proposed Hirst & St-Onge. They define the relatedness between
two concepts based on the quality of links in the lexical chain connecting the
two concepts.

The trace output from these measures is converted to a meta-language. This
meta-language serves as the input ot the visualization module. The trace output
is not used as the input to the visualization, because it might change in the
furure versions of WordNet::Similarity, thus converting it to metalanguage
prevents any of these changes to cause a major changes in the visualization
module.

=head3 Meta-language

The first line in the meta language is the measure name. The next two line list
all the possible shortest paths between the two concepts. The synsets represent
the nodes along these paths, thile the relation names between these synsets
represent the edges. If there is more than one shortest path they are also
listed. The alternate shortest paths are seperated using the OR operator. The
rest of the lines list all the other paths in the hypernym tree. These alternate
hypernym trees also use the same system as used in the shortest path. The next
line is the maximum depth of the hypertree

    path
    cat#n#1 is-a feline#n#1 is-a carnivore#n#1
    dog#n#1 is-a canine#n#2 is-a carnivore#n#1
    carnivore#n#1 is-a placental#n#1 is-a mammal#n#1 is-a vertebrate#n#1 is-a
      chordate#n#1 is-a animal#n#1 is-a organism#n#1 is-a living_thing#n#1 is-a
      object#n#1 is-a entity#n#1 is-a Root#n#1
    Max Depth = 13
    Path length = 5


=head1 SEE ALSO

WordNet::Similarity
WordNet::QueryData

Mailing List: E<lt>wn-similarity@yahoogroups.comE<gt>


=head1 AUTHOR

Saiyam Kohli, University of Minnesota, Duluth
kohli003@d.umn.edu

Ted Pedersen, University of Minnesota, Duluth
tpederse@d.umn.edu


=head1 COPYRIGHT

Copyright (c) 2005-2006, Saiyam Kohli and Ted Pedersen

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to

    The Free Software Foundation, Inc.,
    59 Temple Place - Suite 330,
    Boston, MA  02111-1307, USA.

Note: a copy of the GNU General Public License is available on the web
at <http://www.gnu.org/licenses/gpl.txt> and is included in this
distribution as GPL.txt.

=cut