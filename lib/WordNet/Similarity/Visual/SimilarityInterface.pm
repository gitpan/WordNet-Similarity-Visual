package WordNet::Similarity::Visual::SimilarityInterface;

=head1 NAME

WordNet::Similarity::Visual::SimilarityInterface

=head1 SYNOPSIS

=head2 Basic Usage Example

  use WordNet::Similarity::Visual::SimilarityInterface;

  my $similarity = WordNet::Similarity::Visual::SimilarityInterface->new;

  $similarity->initialize;

  my ($result,$errors,$traces) = $similarity->compute_similarity($word1,$word2,$measure_index);

=head1 DESCRIPTION

This package provides an interface to WordNet::Similarity. It also converts the
trace string to the meta-language.

=head2 Methods

The following methods are defined in this package:

=head3 Public methods

=over

=cut

use 5.008004;
use strict;
use warnings;
our $VERSION = '0.04';
use Gtk2 '-init';
use Gnome2;
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

=item  $obj->new

The constructor for WordNet::Similarity::Visual::SimilarityInterface objects.

Return value: the new blessed object

=cut

sub new
{
  my ($class) = @_;
  my $self = {};
  bless $self, $class;
}

=item  $obj->initialize

To initialize WordNet::Similarity.

Return Value: None

=cut

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


=item  $obj->compute_similarity

Computes the similarity and relatedness scores for two words.

Parameter: Two Words and the Measure Index
"hso","lch","lesk","lin","jcn","path","random","res","vector_pairs","wup"
The measure index can have any of the following values
  - 0 for "all measures"
  - 1 for "Hirst & St-Onge"
  - 2 for "Leacock and Chodorow"
  - 3 for "Adapted Lesk"
  - 4 for "Lin"
  - 5 for "Jiang & Conrath"
  - 6 for "Path Length"
  - 7 for "Random"
  - 8 for "Resnik"
  - 9 for "Vector Pair"
  - 10 for "Wu and Palmer"

Returns: Reference to Hashes containining

  - semantic relatedness/similarity values for all the word senses combination and measures,
  - errorStrings for the word senses and measure which did not return a similarity value
  - TraceString for all the measures that had trace output on

=over

=back

=cut

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
  my $children;
  my @prev_results = $gui->{ similarity_vbox }->{ values_result_box }->get_children();
  foreach $children (@prev_results)
  {
    $gui->{ similarity_vbox }->{ values_result_box }->remove($children);
  }
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
  my $children;
  my @prev_results = $self->{ trace_result_box }->get_children();
  foreach $children (@prev_results)
  {
    $self->{ trace_result_box }->remove($children);
  }
  if($measure=~/path/)
  {
    $meta = convert_to_meta($word1,$word2,$traces->{$word1}{$word2}{$measure},$measure);
    my $canvas = $self->display_tree($meta,450,450);
    $self->{ trace_result_box }->pack_start($canvas, TRUE, TRUE, 0);
  }
  else
  {
    $meta = $traces->{$word1}{$word2}{$measure};
    my $txtbuffer = Gtk2::TextBuffer->new();
    $txtbuffer->set_text($meta);
    my $txtview = Gtk2::TextView->new;
    $txtview->set_editable(FALSE);
    $txtview->set_cursor_visible(FALSE);
    $txtview->set_wrap_mode("word");
    $txtview->set_buffer($txtbuffer);
    $self->{ trace_result_box }->pack_start($txtview, TRUE, TRUE, 0);
  }
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


=item  $obj->convert_to_meta

Converts the Trace String to Meta-language.

Parameter: The two Word senses, Trace String and the Measure name

Returns: A String, the equivalent metalanguage for the trace string.

=over

=cut


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
  my $maxdepth=0;
  foreach $i (0...$#hypertrees)
  {
    if (length($hypertrees[$i])>$maxdepth)
    {
      $maxdepth = length($hypertrees[$i]);
    }
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
  my @syns1;
  my @syns2;
  my $syn;
  my @word1tree;
  my $wn = WordNet::QueryData->new;
  @syns1 = $wn->querySense($word1,"syns");
  foreach $syn (@syns1)
  {
    push @word1tree, grep(/$syn/, @hypertrees);
  }
  my @word2tree;
  @syns2 = $wn->querySense($word2,"syns");
  foreach $syn (@syns2)
  {
    push @word2tree, grep(/$syn/, @hypertrees);
  }
  if($#word1tree == $#hypertrees)
  {
    @word1tree = ();
    foreach $syn (@syns1)
    {
      push @word1tree, grep(!/$syn/, @hypertrees);
    }
  }
  if($#word2tree == $#hypertrees)
  {
    @word2tree = ();
    foreach $syn (@syns2)
    {
      push @word2tree, grep(!/$syn/, @hypertrees);
    }
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
  $trace_return=$trace_return."Max Depth = ".$maxdepth."\n";
  $trace_return=$trace_return.$pathlength."\n";
  return $trace_return;
}




sub display_tree
{
  my ($self,$string,$width,$height)=@_;
  my $canvas = Gnome2::Canvas->new;
  my $canvas_root = $canvas->root;
  my @trace_strings = split "\n",$string;
  my $i;
  my @wps;
  my $diffx;
  my $diffy;
  my $x = 0;
  my $y = 100;
  my $word;
  my %wpspos = ();
  my $prevx;
  my $prevy;
  my $center;
  my %text;
  my %line;
  my $maxx=0;
  my $maxy=0;
  my $minx=0;
  my $miny=0;
  my $hx=0;
  my $hy=0;
  my $shortest_path_group = Gnome2::Canvas::Item->new($canvas_root, "Gnome2::Canvas::Group");
  my $shortest_path_group_wps1 = Gnome2::Canvas::Item->new($shortest_path_group, "Gnome2::Canvas::Group");
  my $shortest_path_group_wps2 = Gnome2::Canvas::Item->new($shortest_path_group, "Gnome2::Canvas::Group");
  if($trace_strings[0]=~/path/)
  {
    @wps= split /\sis-a\s/,$trace_strings[1];
    $diffy = 40;
    $center = $#wps*$diffy/2;
    foreach $i (0...$#wps)
    {
      $word = $wps[$i];
      $diffx = $diffy/2;
      $x = $x+$diffx;
      $y = $y-$diffy;
      if($miny>$y)
      {
        $miny = $y;
      }
      if($maxy<$y)
      {
        $maxy = $y;
      }
      if($minx>$x)
      {
        $minx = $x;
      }
      if($maxx<$x)
      {
        $maxx = $x;
      }
      if($i!=$#wps)
      {
        $wpspos{$word}{"x"}=$x;
        $wpspos{$word}{"y"}=$y;
        $text{$word} = Gnome2::Canvas::Item->new($shortest_path_group_wps1, "Gnome2::Canvas::Text",
                                            x => $x,
                                            y => $y,
                                            fill_color => 'black',
                                            font => 'Sans 10',
                                            anchor => 'GTK_ANCHOR_CENTER',
                                            text => $word);
      }
      else
      {
        $text{$word} = Gnome2::Canvas::Item->new($shortest_path_group, "Gnome2::Canvas::Text",
                                            x => $x,
                                            y => $y-$diffy/5,
                                            fill_color => 'black',
                                            font => 'Sans 10',
                                            anchor => 'GTK_ANCHOR_NW',
                                            text => $word);
        $wpspos{$word}{"x"}=$x;
        $wpspos{$word}{"y"}=$y-$diffy;
      }
      if($i > 0)
      {
        $line{$wps[$i-1]}{$word} = Gnome2::Canvas::Item->new($shortest_path_group_wps1, "Gnome2::Canvas::Line",
                                             points => [$prevx,$prevy-$diffy/5,$x-$diffy/5,$y+$diffy/5],
                                             width_pixels => 1,
                                             last_arrowhead => 1,
                                             arrow_shape_a => 3.57,
                                             arrow_shape_b => 6.93,
                                             arrow_shape_c => 4,
                                             fill_color => 'blue'
                                             );
      }
      $text{$word}->signal_connect (event => sub{
                                                  my ($item, $event) = @_;
#                                                     warn "event ".$event->type."\n";
#                                                   if ($event->type == 29)
#                                                   {
#                                                     print "Hello";
#                                                   }
                                                });
      $prevx = $x;
      $prevy = $y;
    }
    $x = $x+length($wps[$#wps])*6.3;
    @wps= split /\sis-a\s/,$trace_strings[2];
    foreach $i (reverse 0...$#wps)
    {
      $word = $wps[$i];
      if($i!=$#wps)
      {
        $x = $x+$diffx;
        $y = $y+$diffy;
        if($miny>$y)
        {
          $miny = $y;
        }
        if($maxy<$y)
        {
          $maxy = $y;
        }
        if($minx>$x)
        {
          $minx = $x;
        }
        if($maxx<$x)
        {
          $maxx = $x;
        }
        $text{$word} = Gnome2::Canvas::Item->new($shortest_path_group_wps2, "Gnome2::Canvas::Text",
                                            x => $x,
                                            y => $y,
                                            fill_color => 'black',
                                            font => 'Sans 10',
                                            anchor => 'GTK_ANCHOR_CENTER',
                                            text => $word);
        $text{$word}->signal_connect (event => sub {
                                                    my ($item, $event) = @_;
#                                                     warn "event ".$event->type."\n";
                                                   });
        $wpspos{$word}{"x"}=$x;
        $wpspos{$word}{"y"}=$y;
        $line{$word}{$wps[$i+1]} = Gnome2::Canvas::Item->new($shortest_path_group_wps2, "Gnome2::Canvas::Line",
                                            points => [$prevx+$diffy/10,$prevy+$diffy/5,$x-$diffy/10,$y-$diffy/5],
                                            width_pixels => 1,
                                            first_arrowhead => 1,
                                            arrow_shape_a => 3.57,
                                            arrow_shape_b => 6.93,
                                            arrow_shape_c => 4,
                                            fill_color => 'blue'
                                            );
        $prevx = $x;
        $prevy = $y;
      }
      else
      {
        $prevx = $x;
        $prevy = $y;
        next;
      }
    }
  $hx = abs($maxx-$minx)+80;
  $hy = abs($maxy-$miny)+80;
  $canvas->set_size_request($hx,$hy);
  $canvas->set_scroll_region (0, 0, $hx, $hy);
#     print $width/2-$center;
    $shortest_path_group->set(x=>15);
    $shortest_path_group->set(y=>abs($miny)+10);
  }
#  for $i (3...$#trace_strings-2)
#  {
#    @wps = split /\sis-a\s/, $trace_strings[$i];
#  }
#   print $string;
  return $canvas;
}





1;
__END__


=back

=back

=head2 Discussion

This module provides an interface to the various WordNet::Similarity measures.
It implements functions that take as argument two words then find the similarity
scores scores for all the senses of these words. This module also implements the
funtion that takes as input a tracestring and converts it to the meta-language.

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