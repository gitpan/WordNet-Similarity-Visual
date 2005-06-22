package WordNet::Similarity::Visual::SimilarityInterface;

use 5.008004;
use strict;
use warnings;
our $VERSION = '0.01';
use Gtk2 '-init';
use WordNet::QueryData;
use WordNet::Similarity;
use WordNet::Similarity::path;
use WordNet::Similarity::hso;
use WordNet::Similarity::lesk;
use WordNet::Similarity::lin;
use WordNet::Similarity::random;
use WordNet::Similarity::wup;
use WordNet::Similarity::jcn;
use WordNet::Similarity::res;
use WordNet::Similarity::vector_pairs;
use WordNet::Similarity::lch;
use constant TRUE  => 1;
use constant FALSE => 0;
my $vbox;
my $result_box;
my $STOPPED;


sub new
{
  my ($class) = @_;
  my $self = {};
  bless $self, $class;
}

sub initialize
{
  my ($self,$gui) = @_;
  $self->{ vbox } =  Gtk2::VBox->new(FALSE, 6);
  $self->{ vbox }->set_border_width(6);
    my $entry_align = Gtk2::Alignment->new(0.0,0.0,0.3,0.0);
      my $entry_hbox = Gtk2::HBox->new(FALSE,6);
        my $word1_entry = Gtk2::Entry->new;
        my $word2_entry = Gtk2::Entry->new;
        my $measure_touse = Gtk2::ComboBox->new_text;
          $measure_touse->append_text("All Measures");          
          $measure_touse->append_text("Hist & St-Onge");          
          $measure_touse->append_text("Leacock & Chodorow");          
          $measure_touse->append_text("Adapted Lesk");          
          $measure_touse->append_text("Lin");          
          $measure_touse->append_text("Jiang & Conrath");          
          $measure_touse->append_text("Path length");          
          $measure_touse->append_text("Random numbers");          
          $measure_touse->append_text("Resnik");          
          $measure_touse->append_text("Context vector");          
          $measure_touse->append_text("Wu & Palmer");
          $measure_touse->set_active(0); 
        my $compute_button = Gtk2::Button->new('_Compute');
        my $stop_button = Gtk2::Button->new('_Stop');
      $entry_hbox->pack_start($word1_entry, TRUE, TRUE, 0);
      $entry_hbox->pack_start($word2_entry, TRUE, TRUE, 0);
      $entry_hbox->pack_start($measure_touse, TRUE, TRUE, 0);
      $entry_hbox->pack_start($compute_button,FALSE, FALSE, 0);
        $compute_button->signal_connect(clicked=>sub {
                                                        my ($self, $gui)=@_;
                                                        $gui->{ similarity_vbox }->{ STOPPED }=0;
                                                        $gui->set_statusmessage("Similarity", "Computing the Similarity Scores");
                                                        my $word1 = $word1_entry->get_text();
                                                        my $word2 = $word2_entry->get_text();
                                                        my $measure = $measure_touse->get_active();
                                                        my ($result,$errors)=compute_similarity($word1, $word2,$measure, $gui);
                                                        display_similarity_results($gui,$result,$errors,$measure);
                                                      }, $gui);
        $stop_button->signal_connect(clicked=>sub {
                                                    my ($self,$gui)=@_;
                                                    $gui->{ similarity_vbox }->{ STOPPED}=1;
                                                    }, $gui);
      $entry_hbox->pack_start($stop_button,FALSE, FALSE, 0);
    $entry_align->add($entry_hbox);
  $self->{ vbox }->pack_start($entry_align, FALSE, FALSE, 0);
    my $hseparator = Gtk2::HSeparator->new;
  $self->{ vbox }->pack_start($hseparator, FALSE, FALSE, 0);
  $self->{ result_box }=Gtk2::VBox->new(FALSE,4);
  $self->{ vbox }->pack_start($self->{ result_box }, TRUE, TRUE, 0);
}


sub compute_similarity
{
  my ($word1, $word2, $measure_index, $gui) = @_;
  my $self = $gui->{ similarity_vbox };
  my @allmeasures = ("hso","lch","lesk","lin","jcn","path","random","res","vector_pairs","wup");
  my @word1senses;
  my @word2senses;
  if ($self->{ STOPPED }==0)
  {
    $gui->set_statusmessage("Similarity","Finding all the senses for $word1");
     @word1senses = find_allsenses($word1);
  }
  else
  {
    $gui->set_statusmessage("Similarity","Stopped!");
    return 0;
  }
  if($self->{ STOPPED }==0)
  {
    $gui->set_statusmessage("Similarity","Finding all the senses for $word2");
    @word2senses = find_allsenses($word2);
  }
  else
  {
    $gui->set_statusmessage("Similarity","Stopped!");
    return 0;
  }
  my $measurename = $allmeasures[$measure_index-1];
  my $word1sense;
  my $word2sense;
  my %values;
  my %errors;
  my %measure;
  my $module;
  my $wn = WordNet::QueryData->new;
  $measure{"path"} = WordNet::Similarity::path->new($wn);
  $measure{"hso"} = WordNet::Similarity::hso->new($wn);
  $measure{"lesk"} = WordNet::Similarity::lesk->new($wn);
  $measure{"lin"} = WordNet::Similarity::lin->new($wn);
  $measure{"random"} = WordNet::Similarity::random->new($wn);
  $measure{"wup"} = WordNet::Similarity::wup->new($wn);
  $measure{"jcn"} = WordNet::Similarity::jcn->new($wn);
  $measure{"res"} = WordNet::Similarity::res->new($wn);
  $measure{"vector_pairs"} = WordNet::Similarity::vector_pairs->new($wn);
  $measure{"lch"} = WordNet::Similarity::lch->new($wn);
  my $value;
  foreach $word1sense (@word1senses)
  {
    foreach $word2sense (@word2senses)
    {
      if($self->{ STOPPED }==0)
      {
        if($measure_index != 0)
        {
          if($self->{ STOPPED } == 0)
          {
            $gui->set_statusmessage("Similarity","Computing Similarity Score for $word1sense and $word2sense");
            $value=$measure{$allmeasures[$measure_index]}->getRelatedness($word1sense,$word2sense);
            my ($error, $errorString) = $measure{$allmeasures[$measure_index]}->getError();
            if($error)
            {
              $values{$word1sense}{$word2sense}=-1;
              $errors{$word1sense}{$word2sense}=$errorString;
            }
            else
            {
              $values{$word1sense}{$word2sense}=$value;
            }
          }
          else
          {
          }
        }
        else
        {
          foreach $module (@allmeasures)
          {
            if($self->{ STOPPED } == 0)
            {
              $gui->set_statusmessage("Similarity","Computing Similarity Score for $word1sense and $word2sense using $module");
              $value=$measure{$module}->getRelatedness($word1sense,$word2sense);
              my ($error, $errorString) = $measure{$module}->getError();
              if($error)
              {
                $values{$word1sense}{$word2sense}{$module}=-1;
                $errors{$word1sense}{$word2sense}{$module}=$errorString;
              }
              else
              {
                $values{$word1sense}{$word2sense}{$module}=$value;
              }
            }
          }
        }
      }     
    }
  }
  $gui->set_statusmessage("Similarity","Done!");
  return (\%values, \%errors);
}

sub display_similarity_results
{
  my ($gui, $values, $errors, $measure_index) = @_;
  my $result='';
  if ($measure_index!=0)
  {
    my $senset1;
    my $senset2;
    foreach $senset1 (keys %$values)
    {
      foreach $senset2 (keys %{$values->{$senset1}})
      {
        $result = $result."The Relatedness of ".$senset1." and ".$senset2." is ".$values->{$senset1}{$senset2}."\n";
      }
    }
  }
  else
  {
    my $senset1;
    my $senset2;
    my $meas;
    my $i=0;
    my @array;
    foreach $senset1 (keys %$values)
    {
      foreach $senset2 (keys %{$values->{$senset1}})
      {
        $i=0;
        for $meas (keys %{$values->{$senset1}{$senset2}})
        {
          if($errors->{$senset1}{$senset2}{$meas})
          {
          }
          else
          {
            $result = $result."The Relatedness of ".$senset1." and ".$senset2." using ".$meas." is ".$values->{$senset1}{$senset2}{$meas}."\n";
          }
        }
      }
    }
  }
  my $children;
  my @prev_results = $gui->{ similarity_vbox }->{ result_box }->get_children();
  foreach $children (@prev_results)
  {
    $gui->{ similarity_vbox }->{result_box}->remove($children);
  }
  my $txtbuffer = Gtk2::TextBuffer->new;
  $txtbuffer->set_text($result);
  my $txtview = Gtk2::TextView->new;
  $txtview->set_editable(FALSE);
  $txtview->set_cursor_visible(FALSE);
  $txtview->set_wrap_mode("word");
  $txtview->set_buffer($txtbuffer);
  $gui->{ similarity_vbox }->{ result_box }->pack_start($txtview, TRUE, TRUE, 0);
  $gui->{ similarity_vbox }->{ result_box }->show_all;
  $gui->update_ui;
}
sub find_allsenses
{
  my ($word)=@_;
  my @temp = split '#',$word;
  my $wordlevel = $#temp+1;
  my $pos;
  my @wordsenses = ();
  my @wordsense;
  if($wordlevel==1)
  {
    my $wn = WordNet::QueryData->new;
    @temp=$wn->queryWord($word);
    foreach $pos (@temp)
    {
      @wordsense=$wn->queryWord($pos);
      push (@wordsenses, @wordsense);
      @wordsense = ();
    }
  }
  elsif($wordlevel==2)
  {
    my $wn = WordNet::QueryData->new;
    @wordsenses = $wn->queryWord($word);
  }
  else
  {
    $wordsenses[0]=$word
  }
  return @wordsenses;
}


1;
__END__

=head1 NAME

Provides the basic GUI for WordNet::Similarity

=head1 SYNOPSIS
 
  This module provides a graphical user interface for WordNet::Similarity
  
=head1 DESCRIPTION
  
  This module provides a basic graphical user interface for WordNet::Similarity


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
