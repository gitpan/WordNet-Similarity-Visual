package WordNet::Similarity::Visual::QueryDataInterface;

use 5.008004;
use strict;
use warnings;
use Gtk2 '-init';
use WordNet::QueryData;
our $VERSION = '0.01';
use constant TRUE  => 1;
use constant FALSE => 0;
my $vbox;
my $result_box;
sub new
{
  my ($class) = @_;
  my $self = {};
  bless $self, $class;
}

sub initialize
{
  my ($self,$gui) = @_;
  $self->{ vbox }= Gtk2::VBox->new(FALSE, 6);
  $self->{ vbox }->set_border_width(6);
  my $entry_align = Gtk2::Alignment->new(0.0,0.0,0.3,0.0);
    my $entry_hbox = Gtk2::HBox->new(FALSE,6);
      my $back_button = Gtk2::Button->new('<< _Back');
      my $forward_button = Gtk2::Button->new('_Forward >>');
      my $searchword_entry = Gtk2::Entry->new;
      my $search_button = Gtk2::Button->new('_Search');
      my $print_button = Gtk2::Button->new('_Print');
      $entry_hbox->pack_start($back_button,FALSE, FALSE, 0);
      $entry_hbox->pack_start($forward_button,FALSE, FALSE, 0);
      $entry_hbox->pack_start($searchword_entry, TRUE, TRUE, 0);
      $entry_hbox->pack_start($search_button,FALSE, FALSE, 0);
      $entry_hbox->pack_start($print_button,FALSE, FALSE, 0);
      $search_button->signal_connect(clicked=>sub {
                                                    my ($self, $gui)=@_;
                                                    $gui->set_statusmessage("QueryData", "Crawling Through WordNet for Senses!");
                                                    my $word = $searchword_entry->get_text();
                                                    my $result=search_senses($word);
                                                    display_querydata_results($gui,$result);
                                                   }, $gui);
    $entry_align->add($entry_hbox);
  $self->{ vbox }->pack_start($entry_align, FALSE, FALSE, 0);
    my $hseparator = Gtk2::HSeparator->new;
  $self->{ vbox }->pack_start($hseparator, FALSE, FALSE, 0);
  $self->{ result_box }=Gtk2::VBox->new(FALSE,4);
  $self->{ vbox }->pack_start($self->{ result_box }, TRUE, TRUE, 0);
}


sub display_querydata_results
{
  my ($gui, $result)=@_;
  my $wps;
  my %labels;
  my %hbox;
  my %txtview;
  my %txtbuffer;
  my $children;
  my @prev_results = $gui->{ querydata_vbox }->{ result_box }->get_children();
  foreach $children (@prev_results)
  {
    $gui->{ querydata_vbox }->{result_box}->remove($children);
  }
  foreach $wps (sort keys %$result)
  {
    $labels{$wps}=Gtk2::Label->new($wps);
    $hbox{$wps}=Gtk2::HBox->new();
    $txtbuffer{$wps}=Gtk2::TextBuffer->new();
    $txtbuffer{$wps}->set_text($result->{$wps});
    $txtview{$wps}=Gtk2::TextView->new;
    $txtview{$wps}->set_editable(FALSE);
    $txtview{$wps}->set_cursor_visible(FALSE);
    $txtview{$wps}->set_wrap_mode("word");
    $txtview{$wps}->set_buffer($txtbuffer{$wps});
    $hbox{$wps}->pack_start($labels{$wps},FALSE,FALSE,0);
    $hbox{$wps}->pack_start($txtview{$wps},TRUE, TRUE, 0);
    $gui->{ querydata_vbox }->{result_box}->pack_start($hbox{$wps},FALSE, FALSE, 4);
  }
  $gui->{ querydata_vbox }->{result_box}->show_all;
  $gui->update_ui;
}

sub search_senses
{
  my ($word) = @_;
  my $count=0;
  my @wordglos=();
  if (length $word != 0 )
  {
    my $querydata = new WordNet::QueryData;
    $word=lc $word;
	  my @temp = split '#',$word;
    my $wordlevel = $#temp+1;
    my @allsenses = ();
    my $sense;
    my %allres;
    if ($wordlevel == 3)
    {
      @wordglos = $querydata->querySense($word, "glos");
      $allres{$word} = $wordglos[0];
      $count++;
    }
    elsif ($wordlevel == 2)
    {
        my @senses = $querydata->queryWord($word);
        my @wordglos;
        my $glos;
        my $wordsense;
        foreach $wordsense (@senses)
        {
          @wordglos = $querydata->querySense($wordsense,"glos");
          $allres{$wordsense}=$wordglos[0];
          $count++;
        }    
    }
    else
    {
      my @wordpos= ();
      @wordpos=$querydata->queryWord($word);
      my $pos;
      my $wordsense;
      my @senses = ();
      my $glos;
      my @wordglos;
      foreach $pos (@wordpos)
      {
        @senses = $querydata->queryWord($pos);
        foreach $wordsense (@senses)
        {
          @wordglos = $querydata->querySense($wordsense,"glos");
          $allres{$wordsense}=$wordglos[0];
          $count++;
        }
      }
    }
    if ($count > 0)
    {
      return \%allres;
    }
    else
    {
      #$main_window->message("destroy-with-parent","error", "ok", "Word not found in WordNet");      
    }
  }
  else
  {
    #$main_window->message("destroy-with-parent","info", "ok", "Please enter the word you want to search!");
  }
}

1;
__END__
=head1 NAME

Provides the basic GUI for WordNet::QueryData

=head1 SYNOPSIS

  use WordNet::Similarity::Visual;
  
  This module provides a graphical user interface for WordNet::QueryData
  
=head1 DESCRIPTION
  
  This module provides a basic graphical user interface for WordNet::QueryData


=head1 SEE ALSO

Gtk2
Gnome2
WordNet::QueryData

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
