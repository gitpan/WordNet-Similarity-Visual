package WordNet::Similarity::Visual::SimilarityInterface;

use 5.008004;
use strict;
use warnings;
our $VERSION = '0.02';
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
my $trace_result_box;
my $values_result_box;
my $STOPPED;
use constant CONFIG => $ENV{ HOME }."/.wordnet-similarity";


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
                                                        my ($result,$errors,$traces)=compute_similarity($word1, $word2,$measure, $gui);
                                                        display_similarity_results($gui,$result,$errors,$traces,$measure);
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
  $self->{ trace_result_box }=Gtk2::VBox->new(FALSE,4);
  $self->{ values_result_box }=Gtk2::VBox->new(FALSE,4);
    my $hpaned = Gtk2::HPaned->new;
      my $trace_scrollwindow = Gtk2::ScrolledWindow->new;
      $trace_scrollwindow->add_with_viewport($self->{ trace_result_box });
      $trace_scrollwindow->set_policy("GTK_POLICY_AUTOMATIC", "GTK_POLICY_AUTOMATIC");
      my $values_scrollwindow = Gtk2::ScrolledWindow->new;
      $values_scrollwindow->add_with_viewport($self->{ values_result_box });
      $values_scrollwindow->set_policy("GTK_POLICY_AUTOMATIC", "GTK_POLICY_AUTOMATIC");
     $hpaned->add1($values_scrollwindow);
     $hpaned->add2($trace_scrollwindow);
     $hpaned->set_position(320);
  $self->{ vbox }->pack_start($hpaned, TRUE, TRUE, 0);

}

sub compute_similarity
{
  my ($word1, $word2, $measure_index, $gui) = @_;
  my $self = $gui->{ similarity_vbox };
  my @allmeasures = ("hso","lch","lesk","lin","jcn","path","random","res","vector_pairs","wup");
  my @word1senses=[];
  my @word2senses=[];
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
  my %values=();
  my %errors=();
  my %measure=();
  my %traces=();
  my $module;
  my $wn = WordNet::QueryData->new;
  if($self->{ STOPPED }==0)
  {
    $gui->set_statusmessage("Similarity","Initializing WordNet::Similarity");
    $measure{"path"} = WordNet::Similarity::path->new($wn,CONFIG."/config-path.conf");
    $measure{"hso"} = WordNet::Similarity::hso->new($wn,CONFIG."/config-hso.conf");
    $measure{"lesk"} = WordNet::Similarity::lesk->new($wn);
    $measure{"lin"} = WordNet::Similarity::lin->new($wn);
    $measure{"random"} = WordNet::Similarity::random->new($wn);
    $measure{"wup"} = WordNet::Similarity::wup->new($wn,CONFIG."/config-wup.conf");
    $measure{"jcn"} = WordNet::Similarity::jcn->new($wn);
    $measure{"res"} = WordNet::Similarity::res->new($wn);
    $measure{"vector_pairs"} = WordNet::Similarity::vector_pairs->new($wn);
    $measure{"lch"} = WordNet::Similarity::lch->new($wn,CONFIG."/config-lch.conf");
  }
  else
  {
    $gui->set_statusmessage("Similarity","Stopped!");
    return 0;
  }
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
            $value=$measure{$allmeasures[$measure_index-1]}->getRelatedness($word1sense,$word2sense);
            my ($error, $errorString) = $measure{$allmeasures[$measure_index-1]}->getError();
            if($error)
            {
              $values{$word1sense}{$word2sense}=-1;
              $errors{$word1sense}{$word2sense}=$errorString;
            }
            else
            {
              $values{$word1sense}{$word2sense}=$value;
              $traces{$word1sense}{$word2sense}{$allmeasures[$measure_index-1]}=$measure{$allmeasures[$measure_index-1]}->getTraceString;
            }
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
                $traces{$word1sense}{$word2sense}{$module}=$measure{$module}->getTraceString;
              }
            }
          }
        }
      }
    }
  }
  $gui->set_statusmessage("Similarity","Done!");
  return (\%values, \%errors,\%traces);
}

sub display_similarity_results
{
  my ($gui, $values, $errors, $traces, $measure_index) = @_;
  my @allmeasures = ("hso","lch","lesk","lin","jcn","path","random","res","vector_pairs","wup");
  my $measure;
  my $synset1;
  my $synset2;
  my $button;
  my $str;
  if($measure_index!=0)
  {
    $measure = $allmeasures[$measure_index-1];
    foreach $synset1 (keys %$values)
    {
      foreach $synset2 (keys %{$values->{$synset1}})
      {
        $str = sprintf("The Relatedness of %s and %s is %.4f",$synset1, $synset2, $values->{$synset1}{$synset2});
        $button=Gtk2::Button->new_with_label($str);
        $button->signal_connect(clicked=>sub {
                                                my ($self,$gui)=@_;
                                                my $word1;
                                                my $word2;
                                                my @splitlabel;
                                                my $measure;
                                                my $string = $self->get_label();
                                                @splitlabel=split " ",$string;
                                                $measure = $allmeasures[$measure_index-1];
                                                $word1 = $splitlabel[3];
                                                $word2 = $splitlabel[5];
                                                $gui->{ similarity_vbox }->trace_results($word1,$word2,$measure,$traces);
                                                $gui->update_ui;
                                             }, $gui);
        $button->set_relief("none");
        $gui->{ similarity_vbox }->{ values_result_box }->pack_start($button,FALSE, FALSE, 4);
      }
    }
  }
  else
  {
    foreach $synset1 (keys %$values)
    {
      foreach $synset2 (keys %{$values->{$synset1}})
      {
        for $measure (keys %{$values->{$synset1}{$synset2}})
        {
          if($errors->{$synset1}{$synset2}{$measure})
          {
          }
          else
          {
            $str = sprintf("The Relatedness of %s and %s using %s is %.4f",$synset1, $synset2, $measure, $values->{$synset1}{$synset2}{$measure});
            $button=Gtk2::Button->new_with_label($str);
            $button->signal_connect(clicked=>sub {
                                                my ($self,$gui)=@_;
                                                my $word1;
                                                my $word2;
                                                my $measure;
                                                my @splitlabel;
                                                my $string = $self->get_label();
                                                @splitlabel=split " ",$string;
                                                $word1 = $splitlabel[3];
                                                $word2 = $splitlabel[5];
                                                $measure = $splitlabel[7];
                                                $gui->{ similarity_vbox }->trace_results($word1,$word2,$measure,$traces);
                                                $gui->update_ui;
                                             }, $gui);

            $button->set_relief("none");
            $gui->{ similarity_vbox }->{ values_result_box }->pack_start($button,FALSE, FALSE, 4);
          }
        }
      }
    }
  }
  $gui->{ similarity_vbox }->{ values_result_box }->show_all;
  $gui->update_ui;
}

sub trace_results
{
  my ($self,$word1,$word2,$measure,$traces)=@_;
  my $meta;
  if($measure=~/path/)
  {
    $meta = convert_to_meta($word1,$word2,$traces->{$word1}{$word2}{$measure},$measure);
  }
  else
  {
    $meta = $traces->{$word1}{$word2}{$measure};
  }
  my $children;
  my @prev_results = $self->{ trace_result_box }->get_children();
  foreach $children (@prev_results)
  {
    $self->{ trace_result_box }->remove($children);
  }
  my $txtbuffer = Gtk2::TextBuffer->new();
  $txtbuffer->set_text($meta);
  my $txtview = Gtk2::TextView->new;
  $txtview->set_editable(FALSE);
  $txtview->set_cursor_visible(FALSE);
  $txtview->set_wrap_mode("word");
  $txtview->set_buffer($txtbuffer);
  $self->{ trace_result_box }->pack_start($txtview, TRUE, TRUE, 0);
  $self->{ trace_result_box }->show_all;
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

sub convert_to_meta
{
  my ($word1, $word2, $tracestring, $measure) = @_;
  my @trace= split "\n", $tracestring;
  my $length = $#trace;
  my $i;
  my %uniquepaths;
  my $path;
  my $w2tree;
  my @synsets = ();
  my $synset;
  my %lcs_path;
  my %tree;
  my @paths = grep /Shortest path/, @trace;
  my @pathlengths = grep /Path length/, @trace;
  my @hypertrees = grep /HyperTree/, @trace;
  my $pathlength = $pathlengths[0];
  my $wtree;
  my $alt_path;
  my %alt_paths;
  my %allpaths;
  foreach $i (0...$#hypertrees)
  {
    $hypertrees[$i]=~ s/\*Root\*/Root/;
    $hypertrees[$i]=~ s/HyperTree: //;
  }
  foreach $path (@paths)
  {
    $path=~ s/\*Root\*/Root/;
    $path =~ s/Shortest path: //;
    if(length($path)>0)
    {
      $uniquepaths{$path}=1;
      $allpaths{$path}=1;
    }
  }
  my @word1tree = grep /$word1/, @hypertrees;
  my @word2tree = grep /$word2/, @hypertrees;
  if($#word1tree == $#hypertrees)
  {
    @word1tree = grep !/$word2/, @hypertrees;
  }
  if($#word2tree == $#hypertrees)
  {
    @word2tree = grep !/$word1/, @hypertrees;
  }
  @pathlengths = ();
  @trace=();
  foreach $path (keys %uniquepaths)
  {
    @synsets=split " ", $path;
    PATH: foreach $w2tree (@word2tree)
    {
      foreach $synset (@synsets)
      {
        if($w2tree=~/$synset/)
        {
          $lcs_path{$path}{$synset}=1;
          last PATH;
        }
      }
    }
   }
  my %w2_paths=();
  my $w2_path;
  foreach $path (keys %uniquepaths)
  {
    $w2_path='';
    @synsets=split " ", $path;
    foreach $synset (reverse @synsets)
    {
      if(length($w2_path)!=0 )
      {
        $w2_path=$w2_path." is-a ".$synset;
      }
      else
      {
        $w2_path = $synset;
      }
      if(exists $lcs_path{$path}{$synset})
      {
        last;
      }
    }
    $w2_paths{$w2_path}++;
  }
  my %w1_paths=();
  my $w1_path;
  foreach $path (keys %uniquepaths)
  {
    $w1_path='';
    @synsets=split " ", $path;
    foreach $synset (@synsets)
    {
      if(length($w1_path)!=0 )
      {
        $w1_path=$w1_path." is-a ".$synset;
      }
      else
      {
        $w1_path = $synset;
      }
      if(exists $lcs_path{$path}{$synset})
      {
        last;
      }
    }
    $w1_paths{$w1_path}++;
  }

  my $flag=1;
  my $flag2=0;
  foreach $wtree (@hypertrees)
  {
    @synsets = split " ", $wtree;
    foreach $i (reverse 0...$#synsets)
    {
      $flag=1;
      foreach $path (keys %allpaths)
      {
        if($path=~/\b$synsets[$i]\b/)
        {
          $flag=0;
          last;
        }
      }
      if ($flag==1)
      {
        if($flag2==1)
        {
          $alt_path=$alt_path." is-a ".$synsets[$i];
        }
        else
        {
          $flag2=1;
          $alt_path = $synsets[$i+1]." is-a ".$synsets[$i];
        }
      }
      elsif($flag2==1)
      {
        $flag2=0;
        $alt_path=$alt_path." is-a ".$synsets[$i];
        $alt_paths{$alt_path}=1;
        $allpaths{$alt_path}=1;
        $alt_path='';
      }
    }
  }
  my $key;
  my $trace_return=$measure."\n";
  foreach $key (keys %w1_paths)
  {
    $trace_return=$trace_return.$key."\n";
  }
  foreach $key (keys %w2_paths)
  {
    $trace_return=$trace_return.$key."\n";
  }
  foreach $key (keys %alt_paths)
  {
    $trace_return=$trace_return.$key."\n";
  }
  $trace_return=$trace_return.$pathlength."\n";
  return $trace_return;
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
